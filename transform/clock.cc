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

inline IdString to_ff_clk(SigBit clk) { return "\\" + pretty_name(clk, false) + "_FF"; }
inline IdString to_ram_clk(SigBit clk) { return "\\" + pretty_name(clk, false) + "_RAM"; }

void ClockTreeRewriter::run()
{
    if (hier.design->scratchpad_get_bool("emu.clock.rewritten")) {
        log("Design is already processed.\n");
        return;
    }

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

    log("2. Find & create primary clock signals\n");

    std::queue<SigBit> work_queue;
    pool<SigBit> primary_clock_bits;
    dict<SigBit, std::pair<SigBit, SigBit>> primary_to_ff_ram_clk;

    Module *top = hier.design->top_module();
    for (auto &info : database.user_clocks)
        work_queue.push(top->wire(info.port_name));
    work_queue.push(CommonPort::get(top, CommonPort::PORT_MDL_CLK));

    while (!work_queue.empty()) {
        SigBit clk = work_queue.front();
        work_queue.pop();

        if (primary_clock_bits.count(clk))
            continue;

        primary_clock_bits.insert(clk);

        Module *module = clk.wire->module;
        auto &sigmap = sigmaps.at(module->name);

        Wire *ff_clk, *ram_clk;
        if (clk.wire->name == CommonPort::PORT_MDL_CLK.id) {
            ff_clk = CommonPort::get(module, CommonPort::PORT_MDL_CLK_FF);
            ram_clk = CommonPort::get(module, CommonPort::PORT_MDL_CLK_RAM);
        }
        else if (clk.wire->has_attribute("\\associated_ff_clk")) {
            ff_clk = module->wire(clk.wire->get_string_attribute("\\associated_ff_clk"));
            ram_clk = module->wire(clk.wire->get_string_attribute("\\associated_ram_clk"));
        }
        else {
            ff_clk = module->addWire(to_ff_clk(clk));
            ram_clk = module->addWire(to_ram_clk(clk));
            ff_clk->port_input = true;
            ram_clk->port_input = true;
            module->fixup_ports();
        }
        primary_to_ff_ram_clk[clk] = std::make_pair<SigBit, SigBit>(ff_clk, ram_clk);

        log("  Module %s: %s -> %s, %s\n",
            log_id(module),
            pretty_name(clk).c_str(),
            log_id(ff_clk),
            log_id(ram_clk));

        for (Cell *cell : module->cells()) {
            if (hier.celltypes.cell_known(cell->type)) {
                Module *tpl = hier.design->module(cell->type);
                for (auto &conn : cell->connections()) {
                    for (int i = 0; i < GetSize(conn.second); i++) {
                        if (sigmap(conn.second[i]) == clk) {
                            SigBit tpl_bit(tpl->wire(conn.first), i);
                            work_queue.push(tpl_bit);
                            if (tpl_bit.wire->name != CommonPort::PORT_MDL_CLK.id) {
                                cell->setPort(to_ff_clk(tpl_bit), ff_clk);
                                cell->setPort(to_ram_clk(tpl_bit), ram_clk);
                            }
                        }
                    }
                }
            }
        }
    }

    // replace clocks with created FF & RAM clock signals

    log("3. Rewrite cell clock connection\n");

    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = node.data.module;
        auto &sigmap = sigmaps.at(module->name);

        log("Processing module %s\n", log_id(module));

        FfInitVals initvals;
        initvals.set(&sigmap, module);

        // rewrite FFs

        for (Cell *cell : module->cells().to_vector()) {
            if (RTLIL::builtin_ff_cell_types().count(cell->type)) {
                FfData ff(&initvals, cell);
                pool<int> removed_bits;
                if (!ff.has_clk)
                    log_error("FF %s is not driven by clock and is not supported.\n",
                        pretty_name(ff.sig_q).c_str());
                if (!ff.pol_clk)
                    log_error("FF %s is driven by clock negedge and is not supported.\n",
                        pretty_name(ff.sig_q).c_str());
                if (ff.has_sr || ff.has_aload || ff.has_arst)
                    log_error("FF %s has asynchronous set/reset and is not supported.\n",
                        pretty_name(ff.sig_q).c_str());
                SigBit clk = sigmap(ff.sig_clk);
                if (!primary_to_ff_ram_clk.count(clk))
                    log_error("FF %s is clocked by signal %s which is not from top-level clock port. Such self-generated clocks are unsupported.\n",
                        pretty_name(ff.sig_q).c_str(),
                        pretty_name(clk).c_str());

                int offset = 0;
                for (auto chunk : ff.sig_q.chunks()) {
                    if (chunk.is_wire()) {
                        if (chunk.wire->get_bool_attribute(Attr::NoScanchain)) {
                            log("Ignoring FF %s\n",
                                pretty_name(chunk).c_str());

                            std::vector<int> bits;
                            for (int i = offset; i < offset + chunk.size(); i++) {
                                bits.push_back(i);
                                removed_bits.insert(i);
                            }
                            FfData ignored_ff = ff.slice(bits);
                            ignored_ff.emit();
                        }
                        else {
                            log("Rewriting FF %s\n",
                                pretty_name(chunk).c_str());
                        }
                    }
                    offset += chunk.size();
                }

                std::vector<int> bits;
                for (int i = 0; i < ff.width; i++)
                    if (removed_bits.count(i) == 0)
                        bits.push_back(i);
                ff = ff.slice(bits);
                ff.cell = cell;

                ff.sig_clk = primary_to_ff_ram_clk.at(clk).first;
                ff.emit();
            }
        }

        // rewrite memories

        for (auto &mem : Mem::get_all_memories(module)) {
            for (auto &rd : mem.rd_ports) {
                if (rd.arst != State::S0)
                    log_error("Memory %s has a read port with asynchronous reset and is not supported.\n",
                        log_id(mem.memid));
                if (rd.clk_enable) {
                    if (!rd.clk_polarity)
                        log_error("Memory %s has a read port driven by clock negedge and is not supported.\n",
                            log_id(mem.memid));
                    SigBit clk = sigmap(rd.clk);
                    if (!primary_to_ff_ram_clk.count(clk))
                        log_error("Memory %s has a read port clocked by signal %s which is not from top-level clock port. Such self-generated clocks are unsupported.\n",
                            log_id(mem.memid),
                            pretty_name(clk).c_str());
                }
            }
            for (auto &wr : mem.wr_ports) {
                if (!wr.clk_enable)
                    log_error("Memory %s has a write port not driven by clock and is not supported.\n",
                        log_id(mem.memid));
                if (!wr.clk_polarity)
                    log_error("Memory %s has a write port driven by clock negedge and is not supported.\n",
                        log_id(mem.memid));
                SigBit clk = sigmap(wr.clk);
                if (!primary_to_ff_ram_clk.count(clk))
                    log_error("Memory %s has a write port clocked by signal %s which is not from top-level clock port. Such self-generated clocks are unsupported.\n",
                        log_id(mem.memid),
                        pretty_name(clk).c_str());
            }
            if (mem.get_bool_attribute(Attr::NoScanchain)) {
                log("Ignoring RAM %s\n",
                    pretty_name(mem.cell).c_str());
                continue;
            }
            log("Rewriting RAM %s\n",
                pretty_name(mem.memid).c_str());
            for (auto &rd : mem.rd_ports) {
                if (rd.clk_enable) {
                    SigBit clk = sigmap(rd.clk);
                    rd.clk = primary_to_ff_ram_clk.at(clk).second;
                }
            }
            for (auto &wr : mem.wr_ports) {
                SigBit clk = sigmap(wr.clk);
                wr.clk = primary_to_ff_ram_clk.at(clk).second;
            }
            mem.emit();
        }
    }

    // check clock signal use

    ModWalkerCache mwc;

    for (auto clk : primary_clock_bits) {
        Module *module = clk.wire->module;
        auto &modwalker = mwc[module];

        log("Checking module %s\n", log_id(module));

        pool<ModWalker::PortBit> portbits;
        modwalker.get_consumers(portbits, SigSpec(clk));
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

    hier.design->scratchpad_set_bool("emu.clock.rewritten", true);
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestClockTree : public Pass {
    EmuTestClockTree() : Pass("emu_test_clock_tree", "test clock tree helper functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_CLOCK_TREE pass.\n");

        EmulationDatabase database(design);
        PortTransform port(design, database);
        port.run();
        ClockTreeRewriter helper(design, database);
        helper.run();
    }
} EmuTestClockTree;

PRIVATE_NAMESPACE_END
