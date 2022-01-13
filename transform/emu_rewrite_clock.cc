#include "kernel/yosys.h"
#include "kernel/utils.h"
#include "kernel/modtools.h"

#include "emu.h"
#include "interface.h"
#include "designtools.h"

using namespace Emu;
using namespace Emu::Interface;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

struct RewriteClockWorker {

    struct SigMapCache {
        dict<Module*, SigMap> module_sigmap;

        SigMap &operator[](Module *module) {
            if (!module_sigmap.count(module))
                module_sigmap.insert({module, SigMap(module)});
            return module_sigmap.at(module);
        }
    };

    struct ModWalkerCache {
        dict<Module*, ModWalker> module_walker;

        ModWalker &operator[](Module *module) {
            if (!module_walker.count(module))
                module_walker.insert({module, ModWalker(module->design, module)});
            return module_walker.at(module);
        }
    };

    Design *design;
    DesignWalker design_walker;
    SigMapCache sigmap_cache;
    ModWalkerCache modwalker_cache;

    void replace_portbit(Cell *cell, IdString port, int offset, SigBit newbit) {
        SigSpec new_port = cell->getPort(port);
        new_port[offset] = newbit;
        cell->setPort(port, new_port);
    }

    void rewrite_clock_bits(SigBit clk, SigBit ff_clk, SigBit ram_clk) {
        // Note: we assume an identified clock port is connected to dut clock in all module instantiations

        if (!clk.is_wire())
            return;

        Module *module = clk.wire->module;
        SigMap &sigmap = sigmap_cache[module];
        sigmap.apply(clk);

        // Identify output ports

        pool<SigBit> output_bits;

        for (auto wire : module->wires())
            if (wire->port_output)
                for (SigBit b : SigSpec(wire))
                    if (sigmap(b) == clk)
                        output_bits.insert(b);

        for (auto cell : design_walker.instances_of(module)) {
            for (auto output_bit : output_bits) {
                // Add output ports

                log("Rewriting output port %s.%s[%d]\n",
                    log_id(module), log_id(output_bit.wire), output_bit.offset);

                IdString portname = output_bit.wire->name;
                IdString ff_portname = portname.str() + "$EMU$FF$CLK";
                IdString ram_portname = portname.str() + "$EMU$RAM$CLK";

                bool do_fixup_ports = false;

                Wire *ff_clk_port = module->wire(ff_portname);
                if (ff_clk_port == nullptr) {
                    ff_clk_port = module->addWire(ff_portname, output_bit.wire);
                    do_fixup_ports = true;
                }

                Wire *ram_clk_port = module->wire(ram_portname);
                if (ram_clk_port == nullptr) {
                    ram_clk_port = module->addWire(ram_portname, output_bit.wire);
                    do_fixup_ports = true;
                }

                if (do_fixup_ports)
                    module->fixup_ports();

                module->connect(SigBit(ff_clk_port, output_bit.offset), ff_clk);
                module->connect(SigBit(ram_clk_port, output_bit.offset), ram_clk);

                if (!cell->hasPort(portname))
                    continue;

                // Rewrite outer module

                if (!cell->hasPort(ff_portname))
                    cell->setPort(ff_portname, cell->module->addWire(NEW_ID, GetSize(ff_clk_port)));

                if (!cell->hasPort(ram_portname))
                    cell->setPort(ram_portname, cell->module->addWire(NEW_ID, GetSize(ram_clk_port)));

                SigBit cell_bit = cell->getPort(portname)[output_bit.offset];
                SigBit cell_ff_bit = cell->getPort(ff_portname)[output_bit.offset];
                SigBit cell_ram_bit = cell->getPort(ram_portname)[output_bit.offset];
                rewrite_clock_bits(cell_bit, cell_ff_bit, cell_ram_bit);
            }
        }

        // Identify input ports of cells

        ModWalker &modwalker = modwalker_cache[module];

        pool<ModWalker::PortBit> portbits;
        modwalker.get_consumers(portbits, SigSpec(clk));

        for (auto &portbit : portbits) {
            Cell * cell = portbit.cell;

            if (RTLIL::builtin_ff_cell_types().count(cell->type)) {
                for (auto chunk : cell->getPort(ID::Q).chunks())
                    if (chunk.is_wire())
                        log("Rewriting ff cell %s.%s.%s[%d]\n",
                            log_id(module), log_id(chunk.wire), log_id(portbit.port), portbit.offset);

                replace_portbit(portbit.cell, portbit.port, portbit.offset, ff_clk);
                continue;
            }

            if (cell->is_mem_cell()) {
                log("Rewriting mem cell %s.%s.%s[%d]\n",
                    log_id(module), log_id(cell), log_id(portbit.port), portbit.offset);

                replace_portbit(portbit.cell, portbit.port, portbit.offset, ram_clk);
                continue;
            }

            Module *tpl = design->module(cell->type);

            if (tpl == nullptr)
                log_error("Cell type %s is unknown and its clock cannot be rewritten\n",
                    cell->type.c_str());

            log("Rewriting input port %s.%s[%d]\n",
                log_id(tpl), log_id(portbit.port), portbit.offset);

            IdString portname = portbit.port;
            IdString ff_portname = portname.str() + "$EMU$FF$CLK";
            IdString ram_portname = portname.str() + "$EMU$RAM$CLK";

            // Add cell ports

            SigSpec cell_port = cell->getPort(portname);

            if (!cell->hasPort(ff_portname))
                cell->setPort(ff_portname, Const(0, GetSize(cell_port)));

            if (!cell->hasPort(ram_portname))
                cell->setPort(ram_portname, Const(0, GetSize(cell_port)));

            replace_portbit(cell, ff_portname, portbit.offset, ff_clk);
            replace_portbit(cell, ram_portname, portbit.offset, ram_clk);

            // Rewrite inner module

            Wire *tpl_port = tpl->wire(portname);

            bool do_fixup_ports = false;

            Wire *tpl_ff_port = tpl->wire(ff_portname);
            if (tpl_ff_port == nullptr) {
                tpl_ff_port = tpl->addWire(ff_portname, tpl_port);
                do_fixup_ports = true;
            }

            Wire *tpl_ram_port = tpl->wire(ram_portname);
            if (tpl_ram_port == nullptr) {
                tpl_ram_port = tpl->addWire(ram_portname, tpl_port);
                do_fixup_ports = true;
            }

            if (do_fixup_ports)
                tpl->fixup_ports();

            SigBit tpl_bit = SigBit(tpl_port, portbit.offset);
            SigBit tpl_ff_bit = SigBit(tpl_ff_port, portbit.offset);
            SigBit tpl_ram_bit = SigBit(tpl_ram_port, portbit.offset);
            rewrite_clock_bits(tpl_bit, tpl_ff_bit, tpl_ram_bit);
        }
    }

    void run() {
        for (Module *module : design->modules()) {
            for (Wire *wire : module->wires().to_vector()) {
                if (wire->get_string_attribute(AttrIntfPort) == "dut_clk") {
                    log("Processing %s.%s\n", log_id(module), log_id(wire));
                    wire->attributes.erase(ID::keep);
                    wire->attributes.erase(AttrIntfPort);
                    Wire *ff_clk = module->addWire(module->uniquify("\\ut_ff_clk"));
                    ff_clk->set_bool_attribute(ID::keep);
                    ff_clk->set_string_attribute(AttrIntfPort, "dut_ff_clk");
                    Wire *ram_clk = module->addWire(module->uniquify("\\dut_ram_clk"));
                    ram_clk->set_bool_attribute(ID::keep);
                    ram_clk->set_string_attribute(AttrIntfPort, "dut_ram_clk");
                    rewrite_clock_bits(wire, ff_clk, ram_clk);
                }
            }
            module->set_bool_attribute(AttrClkRewritten);
        }
    }

    RewriteClockWorker(Design *design) : design(design), design_walker(design) {}
};

struct EmuRewriteClockPass : public Pass {
    EmuRewriteClockPass() : Pass("emu_rewrite_clock", "rewrite clock for emulation") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_rewrite_clock\n");
        log("\n");
        log("This command rewrites dut_clk in the design to dut_ff_clk & dut_ram_clk.\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_REWRITE_CLOCK pass.\n");
        log_push();

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            break;
        }
        extra_args(args, argidx, design);

        RewriteClockWorker worker(design);
        worker.run();

        log_pop();
    }
} EmuRewriteClockPass;

PRIVATE_NAMESPACE_END
