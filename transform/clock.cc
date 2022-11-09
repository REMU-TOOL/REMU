#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "attr.h"
#include "port.h"
#include "clock.h"
#include "utils.h"
#include "walker_cache.h"

#include <queue>

USING_YOSYS_NAMESPACE

using namespace Emu;

void ClockTreeHelper::run()
{
    log("Rewriting clock tree ...\n");

    // build sigmaps containing submodule wire propagations

    log("1. Analyze cross-boundary connections\n");

    dict<IdString, SigMap> sigmaps;

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = node.data.module;
        sigmaps[module->name] = SigMap(module);
        auto &sigmap = sigmaps.at(module->name);

        // import submodule connections

        for (auto &edge : node.outEdges()) {
            Cell *inst = edge.data.inst;
            Module *sub = edge.toNode().data.module;
            SigSpec inputs_outer, inputs_inner, outputs_outer, outputs_inner;
            for (auto &conn : inst->connections()) {
                SigSpec inner = sub->wire(conn.first);
                SigSpec outer = conn.second;
                outer.extend_u0(GetSize(inner));
                if (hier.celltypes.cell_input(inst->type, conn.first)) {
                    inputs_inner.append(inner);
                    inputs_outer.append(outer);
                }
                else {
                    outputs_inner.append(inner);
                    outputs_outer.append(outer);
                }
            }
            SigSpec outputs_inner_mapped = sigmaps.at(sub->name)(outputs_inner);
            SigSpec outputs_outer_mapped = outputs_outer;
            outputs_inner_mapped.replace(inputs_inner, inputs_outer, &outputs_outer_mapped);
#if 0
            for (int i=0; i<GetSize(outputs_outer); i++) {
                if (outputs_outer[i] != outputs_outer_mapped[i]) {
                    log("%s: %s -> %s\n",
                        pretty_name(module->name).c_str(),
                        pretty_name(outputs_outer[i]).c_str(),
                        pretty_name(outputs_outer_mapped[i]).c_str());
                }
            }
#endif
            sigmap.add(outputs_outer, outputs_outer_mapped);
        }

        // promote input ports

        for (auto port : module->ports) {
            Wire *wire = module->wire(port);
            if (wire->port_input)
                sigmap.add(wire);
        }
    }

    // find all primary clock bits

    log("2. Find primary clock signals\n");

    std::queue<SigBit> work_queue;

    for (auto &b : primary_clock_bits[hier.top])
        work_queue.push(b);

    while (!work_queue.empty()) {
        SigBit clk = work_queue.front();
        work_queue.pop();

        Module *module = clk.wire->module;
        auto &sigmap = sigmaps.at(module->name);

        for (Cell *cell : module->cells()) {
            if (hier.celltypes.cell_known(cell->type)) {
                Module *tpl = hier.design->module(cell->type);
                for (auto &conn : cell->connections()) {
                    for (int i = 0; i < GetSize(conn.second); i++) {
                        if (sigmap(conn.second[i]) == clk) {
                            SigBit tpl_bit(tpl->wire(conn.first), i);
                            primary_clock_bits[cell->type].insert(tpl_bit);
                            work_queue.push(tpl_bit);
                        }
                    }
                }
            }
        }
    }

    for (auto &it : primary_clock_bits) {
        log("  Module %s:", pretty_name(it.first).c_str());
        for (auto &b : it.second)
            log(" %s", pretty_name(b).c_str());
        log("\n");
    }

    // replace clock aliases to primary clock signals

    log("3. Replace clock signals with primary clocks\n");

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = node.data.module;
        auto &sigmap = sigmaps.at(module->name);

        // scan FFs

        for (Cell *cell : module->cells().to_vector()) {
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
                sigmap.apply(ff.sig_clk);
                ff.emit();
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
                    sigmap.apply(rd.clk);
                }
            }
            for (auto &wr : mem.wr_ports) {
                if (!wr.clk_enable)
                    log_error("Memory %s has a write port not driven by clock and is not supported.\n",
                        log_id(mem.memid));
                if (!wr.clk_polarity)
                    log_error("Memory %s has a write port driven by clock negedge and is not supported.\n",
                        log_id(mem.memid));
                sigmap.apply(wr.clk);
            }
            mem.emit();
        }
    }

    // check clock signal use

    ModWalkerCache mwc;

    for (Module *module : hier.design->modules()) {
        auto &modwalker = mwc[module];

        if (primary_clock_bits.count(module->name)) {
            pool<ModWalker::PortBit> portbits;
            modwalker.get_consumers(portbits, primary_clock_bits.at(module->name));
            for (auto &portbit : portbits) {
                Cell *cell = portbit.cell;
                SigBit bit = cell->getPort(portbit.port)[portbit.offset];
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
                else if (!hier.celltypes.cell_known(cell->type)) {
                    log_error("Clock signal %s used in combinational logic (%s, %s)\n",
                        pretty_name(bit).c_str(),
                        log_id(cell),
                        log_id(portbit.port));
                }
            }
        }
    }
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestClockTree : public Pass {
    EmuTestClockTree() : Pass("emu_test_clock_tree", "test clock tree helper functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_CLOCK_TREE pass.\n");

        EmulationDatabase database(design);
        PortTransformer port(design, database);
        port.promote();
        ClockTreeHelper helper(design);
        Module *top = design->top_module();
        for (auto &info : database.user_clocks)
            helper.addTopClock(top->wire(info.port_name));
        helper.run();
    }
} EmuTestClockTree;

PRIVATE_NAMESPACE_END
