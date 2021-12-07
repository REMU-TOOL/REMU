#include "kernel/yosys.h"
#include "kernel/utils.h"
#include "kernel/modtools.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

void replace_portbit(ModWalker::PortBit &portbit, SigBit &newbit) {
    SigSpec new_port = portbit.cell->getPort(portbit.port);
    new_port[portbit.offset] = newbit;
    portbit.cell->setPort(portbit.port, new_port);
}

// Rewrite module to assign FFs & Mems with separated ff_clk & mem_clk
void rewrite_clock(Module *module, SigBit orig_clk, SigBit ff_clk, SigBit mem_clk) {
    ModWalker modwalker(module->design, module);

    pool<ModWalker::PortBit> portbits;
    modwalker.get_consumers(portbits, SigSpec(orig_clk)); // Workaround: the SigBit-version get_consumers is now inaccessible
    for (auto &portbit : portbits) {
        if (RTLIL::builtin_ff_cell_types().count(portbit.cell->type)) {
            replace_portbit(portbit, ff_clk);
        }
        else if (portbit.cell->is_mem_cell()) {
            replace_portbit(portbit, mem_clk);
        }
        else {
            Module *target = module->design->module(portbit.cell->type);

            if (!target)
                log_error("Unknown cell type cannot be handled by rewrite_clock: %s\n",
                    portbit.cell->type.c_str());

            // Rewrite submodule
            Wire *target_port = target->wire(portbit.port);
            std::string new_name = target_port->name.str() + "$EMU$ADDED$PORT";
            if (!target_port->has_attribute(AttrClkPortRewritten)) {
                Wire *new_port = target->addWire(new_name);
                new_port->port_input = true;
                target->fixup_ports();

                SigBit target_ff_clk = SigSpec(target_port)[portbit.offset];
                rewrite_clock(target, target_ff_clk, target_ff_clk, new_port);

                target_port->set_bool_attribute(AttrClkPortRewritten);
            }

            replace_portbit(portbit, ff_clk);
            portbit.cell->setPort(new_name, mem_clk);
        }
    }
}

void process_emulib(Module *module, Database &db) {
    // check if already processed
    if (module->get_bool_attribute(AttrLibProcessed)) {
        log_warning("Module %s is already processed by emu_process_lib\n", log_id(module));
        return;
    }

    std::vector<Cell *> cells_to_remove;
    SigSpec ff_clk_sigs, mem_clk_sigs, reset_sigs, trig_sigs;

    EmulibData &emulib = db.emulib[module->name];

    for (auto cell : module->cells()) {
        Module *target = module->design->module(cell->type);

        if (target) {
            std::string component = target->get_string_attribute(AttrEmulibComponent);

            // clock instance
            if (component == "clock") {
                Wire *ff_clk = module->addWire(NEW_ID);
                Wire *mem_clk = module->addWire(NEW_ID);
                SigBit orig_clk = cell->getPort("\\clock")[0];
                rewrite_clock(module, orig_clk, ff_clk, mem_clk);
                ff_clk_sigs.append(ff_clk);
                mem_clk_sigs.append(mem_clk);
                DutClkInfo info;
                info.name = get_hier_name(cell);
                info.cycle_ps = 0; // TODO
                info.phase_ps = 0; // TODO
                emulib.clk.push_back(info);
                cells_to_remove.push_back(cell);
            }

            // reset instance
            if (component == "reset") {
                reset_sigs.append(cell->getPort("\\reset"));
                DutRstInfo info;
                info.name = get_hier_name(cell);
                info.duration_ns = 0; // TODO
                emulib.rst.push_back(info);
                cells_to_remove.push_back(cell);
            }

            // trigger instance
            if (component == "trigger") {
                trig_sigs.append(cell->getPort("\\trigger"));
                DutTrigInfo info;
                info.name = get_hier_name(cell);
                emulib.trig.push_back(info);
                cells_to_remove.push_back(cell);
            }
        }
    }

    for (auto &cell : cells_to_remove)
        module->remove(cell);

    // process submodules

    for (auto &cell : module->selected_cells()) {
        Module *target = module->design->module(cell->type);
        if (target && target->get_bool_attribute(AttrLibProcessed)) {
            EmulibData target_emulib = db.emulib.at(target->name).nest(cell);

            Wire *sub_ff_clk = module->addWire(NEW_ID, GetSize(target_emulib.clk));
            cell->setPort(PortDutFfClk, sub_ff_clk);
            ff_clk_sigs.append(sub_ff_clk);
            Wire *sub_mem_clk = module->addWire(NEW_ID, GetSize(target_emulib.clk));
            cell->setPort(PortDutRamClk, sub_mem_clk);
            mem_clk_sigs.append(sub_mem_clk);
            emulib.clk.insert(emulib.clk.end(), target_emulib.clk.begin(), target_emulib.clk.end());

            Wire *sub_reset = module->addWire(NEW_ID, GetSize(target_emulib.rst));
            cell->setPort(PortDutRst, sub_reset);
            reset_sigs.append(sub_reset);
            emulib.rst.insert(emulib.rst.end(), target_emulib.rst.begin(), target_emulib.rst.end());

            Wire *sub_trig = module->addWire(NEW_ID, GetSize(target_emulib.trig));
            cell->setPort(PortDutTrig, sub_trig);
            trig_sigs.append(sub_trig);
            emulib.trig.insert(emulib.trig.end(), target_emulib.trig.begin(), target_emulib.trig.end());
        }
    }

    // add ports & connect signals

    Wire *ff_clk_wire = module->addWire(PortDutFfClk, GetSize(ff_clk_sigs));
    ff_clk_wire->port_input = true;
    module->connect(ff_clk_sigs, ff_clk_wire);

    Wire *mem_clk_wire = module->addWire(PortDutRamClk, GetSize(mem_clk_sigs));
    mem_clk_wire->port_input = true;
    module->connect(mem_clk_sigs, mem_clk_wire);

    Wire *reset_wire = module->addWire(PortDutRst, GetSize(reset_sigs));
    reset_wire->port_input = true;
    module->connect(reset_sigs, reset_wire);

    Wire *trig_wire = module->addWire(PortDutTrig, GetSize(trig_sigs));
    trig_wire->port_output = true;
    module->connect(trig_wire, trig_sigs);

    module->fixup_ports();

    module->set_bool_attribute(AttrLibProcessed);
}

struct EmuProcessLibPass : public Pass {
    EmuProcessLibPass() : Pass("emu_process_lib", "process emulation libraries in design") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_process_lib [options]\n");
        log("\n");
        log("This command replaces emulation libraries in the design with emulation logic.\n");
        log("\n");
        log("    -db <database>\n");
        log("        specify the emulation database or the default one will be used.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PROCESS_LIB pass.\n");

        std::string db_name;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-db" && argidx+1 < args.size()) {
                db_name = args[++argidx];
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        Database &db = Database::databases[db_name];

        TopoSort<RTLIL::Module*, IdString::compare_ptr_by_name<RTLIL::Module>> topo_modules;
        for (auto &mod : design->selected_modules()) {
            topo_modules.node(mod);
            for (auto &cell : mod->selected_cells()) {
                Module *tpl = design->module(cell->type);
                if (tpl && design->selected_module(tpl)) {
                    topo_modules.edge(tpl, mod);
                }
            }
        }

		if (!topo_modules.sort())
			log_error("Recursive instantiation detected.\n");

        for (auto &mod : topo_modules.sorted) {
            log("Processing module %s\n", mod->name.c_str());
            process_emulib(mod, db);
        }
    }
} EmuProcessLibPass;

PRIVATE_NAMESPACE_END
