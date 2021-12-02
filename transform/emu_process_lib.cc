#include "kernel/yosys.h"
#include "kernel/utils.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

void process_emulib(Module *module, Database &db) {
    // check if already processed
    if (module->get_bool_attribute(AttrLibProcessed)) {
        log_warning("Module %s is already processed by emu_process_lib\n", log_id(module));
        return;
    }

    std::vector<Cell *> cells_to_remove;
    SigSpec clock_sigs, reset_sigs, trig_sigs;

    EmulibData &emulib = db.emulib[module->name];

    for (auto cell : module->cells()) {
        // TODO: handle multiple clocks & resets
        if (cell->type.c_str()[0] == '\\') {
            Module *target = module->design->module(cell->type);

            // clock instance
            if (target->get_bool_attribute("\\emulib_clock")) {
                clock_sigs.append(cell->getPort("\\clock"));
                DutClkInfo info;
                info.name = get_hier_name(cell);
                info.cycle_ps = 0; // TODO
                info.phase_ps = 0; // TODO
                emulib.clk.push_back(info);
                cells_to_remove.push_back(cell);
            }

            // reset instance
            if (target->get_bool_attribute("\\emulib_reset")) {
                reset_sigs.append(cell->getPort("\\reset"));
                DutRstInfo info;
                info.name = get_hier_name(cell);
                info.duration_ns = 0; // TODO
                emulib.rst.push_back(info);
                cells_to_remove.push_back(cell);
            }

            // trigger instance
            if (target->get_bool_attribute("\\emulib_trigger")) {
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

            Wire *sub_clock = module->addWire(NEW_ID, GetSize(target_emulib.clk));
            cell->setPort(PortDutClk, sub_clock);
            clock_sigs.append(sub_clock);
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

    Wire *clock_wire = module->addWire(PortDutClk, GetSize(clock_sigs));
    clock_wire->port_input = true;
    module->connect(clock_sigs, clock_wire);

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
