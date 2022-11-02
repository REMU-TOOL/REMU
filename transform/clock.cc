#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "attr.h"
#include "clock.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

void ClockTreeAnalyzer::analyze_clocked_cells()
{
    clock_signals.clear();

    for (Module *module : design->modules()) {
        log("Finding clocked cells in module %s ...\n", log_id(module));

        auto &signals = clock_signals[module];
        auto &modwalker = modwalkers[module];
        auto &sigmap = modwalker.sigmap;

        // scan FFs

        for (Cell *cell : module->cells()) {
            if (RTLIL::builtin_ff_cell_types().count(cell->type)) {
                FfData ff(nullptr, cell);
                if (!ff.has_clk)
                    log_error("FF %s is not driven by clock and is not supported.\n",
                        pretty_name(ff.sig_q).c_str());
                if (!ff.pol_clk)
                    log_error("FF %s is driven by clock negedge and is not supported.\n",
                        pretty_name(ff.sig_q).c_str());
                if (ff.has_sr || ff.has_aload || ff.has_arst)
                    log_error("FF %s has asynchronous set/reset and is not supported.\n",
                        pretty_name(ff.sig_q).c_str());
                signals.insert(sigmap(ff.sig_clk));
            }
        }

        // scan memories

        for (auto &mem : Mem::get_all_memories(module)) {
            for (auto &rd : mem.rd_ports) {
                if (rd.arst != State::S0)
                    log_error("Memory %s has a read port with asynchronous reset and is not supported.\n",
                        log_id(mem.memid));
                if (rd.clk_enable) {
                    if (!rd.clk_polarity)
                        log_error("Memory %s has a read port driven by clock negedge and is not supported.\n",
                            log_id(mem.memid));
                    signals.insert(sigmap(rd.clk));
                }
            }
            for (auto &wr : mem.wr_ports) {
                if (!wr.clk_enable)
                    log_error("Memory %s has a write port not driven by clock and is not supported.\n",
                        log_id(mem.memid));
                if (!wr.clk_polarity)
                    log_error("Memory %s has a write port driven by clock negedge and is not supported.\n",
                        log_id(mem.memid));
                signals.insert(sigmap(wr.clk));
            }
        }

        // check clock signal use

        pool<ModWalker::PortBit> portbits;
        modwalker.get_consumers(portbits, signals);
        for (auto &portbit : portbits) {
            Cell *cell = portbit.cell;
            SigBit bit = cell->getPort(portbit.port)[portbit.offset];
            sigmap.apply(bit);
            if (RTLIL::builtin_ff_cell_types().count(cell->type)) {
                if (portbit.port != ID::CLK)
                    log_error("Clock signal %s used in non-clock port (%s, %s)\n",
                        pretty_name(bit).c_str(),
                        pretty_name(cell->getPort(ID::Q)).c_str(),
                        log_id(portbit.port));
            }
            else if (cell->is_mem_cell()) {
                if (portbit.port != ID::CLK &&
                    portbit.port != ID::RD_CLK &&
                    portbit.port != ID::WR_CLK)
                    log_error("Clock signal %s used in non-clock port (%s, %s)\n",
                        pretty_name(bit).c_str(),
                        log_id(cell),
                        log_id(portbit.port));
            }
            else if (cell->type[0] != '\\') {
                log_error("Clock signal %s used in combinational logic (%s, %s)\n",
                    pretty_name(bit).c_str(),
                    log_id(cell),
                    log_id(portbit.port));
            }
        }
    }
}

void ClockTreeAnalyzer::analyze_clock_propagation()
{
    clock_ports.clear();

    pool<Module*> working_list, changed_list;
    working_list = design->modules().to_pool();

    while (!working_list.empty()) {
        for (Module *module : working_list) {
            log("Analyzing clock propagation in module %s ...\n", log_id(module));

            // do not call another modwalkers[] while modwalker is valid
            auto &modwalker = modwalkers[module];
            auto &sigmap = modwalker.sigmap;
            auto &signals = clock_signals.at(module);

            auto &hier_node = hier.dag.findNode(module->name);

            // identify signals by ports

            for (SigBit b : clock_ports[module])
                signals.insert(sigmap(b));

            // identify signals by submodule ports

            for (auto &out : hier_node.outEdges()) {
                Cell *inst = module->cell(out.name.second);
                Module *submodule = design->module(out.toNode().name);

                for (SigBit s_b : clock_ports[submodule]) {
                    SigBit b = inst->getPort(s_b.wire->name)[s_b.offset];
                    signals.insert(sigmap(b));
                }
            }

            // identify ports by signals

            bool ports_changed = false;

            for (auto port : module->ports) {
                Wire *wire = module->wire(port);
                for (SigBit b : SigSpec(wire))
                    if (signals.count(sigmap(b)) != 0) {
                        auto &ports = clock_ports[module];
                        if (ports.count(b) == 0)
                            ports_changed = true;
                        ports.insert(b);
                    }
            }

            if (ports_changed)
                for (auto &in : hier_node.inEdges())
                    changed_list.insert(design->module(in.fromNode().name));

            // identify submodule ports by signals

            for (auto &out : hier_node.outEdges()) {
                Cell *inst = module->cell(out.name.second);
                Module *submodule = design->module(out.toNode().name);
                bool submodule_ports_changed = false;

                for (auto port : submodule->ports) {
                    Wire *wire = submodule->wire(port);
                    for (SigBit s_b : SigSpec(wire)) {
                        SigBit b = inst->getPort(s_b.wire->name)[s_b.offset];
                        if (signals.count(sigmap(b)) != 0) {
                            auto &submodule_ports = clock_ports[submodule];
                            if (submodule_ports.count(s_b) == 0)
                                submodule_ports_changed = true;
                            submodule_ports.insert(s_b);
                        }
                    }
                }

                if (submodule_ports_changed)
                    changed_list.insert(submodule);
            }
        }

        // scan affected modules again
        working_list.swap(changed_list);
        changed_list.clear();
    }
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestAnalyzeClock : public Pass {
    EmuTestAnalyzeClock() : Pass("emu_test_analyze_clock", "test clock analyzer functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_ANALYZE_CLOCK pass.\n");

        Hierarchy hier(design);
        ClockTreeAnalyzer analyzer(design, hier);
        analyzer.analyze();

        for (Module *module : design->modules()) {
            log("module: %s\n", log_id(module));
            log("  ports:\n");
            for (SigBit b : analyzer.clock_ports.at(module))
                log("    %s (%s)\n", pretty_name(b).c_str(), b.wire->port_input ? "IN" : "OUT");
            log("  signals:\n");
            for (SigBit b : analyzer.clock_signals.at(module))
                log("    %s\n", pretty_name(b).c_str());
        }
    }
} EmuTestAnalyzeClock;

PRIVATE_NAMESPACE_END
