#include "kernel/yosys.h"
#include "kernel/ff.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

#include <queue>

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

struct ClockWorker {

    EmulationDatabase &database;
    EmulationRewriter &rewriter;
    DesignInfo &designinfo;

    void rewrite(SigBit orig_clk, RewriterWire *ff_clk, RewriterWire *ram_clk);
    void run();

    ClockWorker(EmulationDatabase &database, EmulationRewriter &rewriter)
        : database(database), rewriter(rewriter), designinfo(rewriter.design()) {}

};

void ClockWorker::rewrite(SigBit orig_clk, RewriterWire *ff_clk, RewriterWire *ram_clk) {

    log("Transforming clock signal %s to %s/%s\n",
        designinfo.flat_name_of(orig_clk).c_str(),
        ff_clk->name().c_str(),
        ram_clk->name().c_str()
    );

    for (auto portbit : designinfo.get_consumers(orig_clk)) {
        Cell *cell = portbit.cell;

        if (RTLIL::builtin_ff_cell_types().count(cell->type)) {
            FfData ff(nullptr, cell);
            pool<int> removed_bits;

            int offset = 0;
            for (auto chunk : ff.sig_q.chunks()) {
                if (chunk.is_wire()) {
                    if (designinfo.check_hier_attr(Attr::NoScanchain, chunk.wire)) {
                        log("Ignoring ff cell %s\n",
                            designinfo.flat_name_of(chunk).c_str());

                        std::vector<int> bits;
                        for (int i = offset; i < offset + chunk.size(); i++) {
                            bits.push_back(i);
                            removed_bits.insert(i);
                        }
                        FfData ignored_ff = ff.slice(bits);
                        ignored_ff.emit();
                    }
                    else {
                        log("Rewriting ff cell %s\n",
                            designinfo.flat_name_of(chunk).c_str());
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

            log_assert(portbit.port == ID::CLK);
            log_assert(portbit.offset == 0);
            ff.sig_clk = ff_clk->get(cell->module);
            ff.emit();

            continue;
        }

        if (cell->is_mem_cell()) {
            if (designinfo.check_hier_attr(Attr::NoScanchain, cell)) {
                log("Ignoring mem cell %s\n",
                    designinfo.flat_name_of(cell).c_str());
            }
            else {
                log("Rewriting mem cell %s\n",
                    designinfo.flat_name_of(cell).c_str());

                SigSpec new_port = cell->getPort(portbit.port);
                new_port[portbit.offset] = ram_clk->get(cell->module);
                cell->setPort(portbit.port, new_port);
            }

            continue;
        }

        log_error("unrecognized cell %s which cannot be rewritten\n",
            designinfo.flat_name_of(cell).c_str());
    }

    log("------------------------------\n");

}

void ClockWorker::run() {

    // Rewrite mdl_clk

    auto mdl_clk        = rewriter.clock("mdl_clk");
    auto mdl_clk_ff     = rewriter.clock("mdl_clk_ff");
    auto mdl_clk_ram    = rewriter.clock("mdl_clk_ram");

    SigBit mdl_clk_en = mdl_clk->getEnable();
    mdl_clk_ff->setEnable(mdl_clk_en);
    mdl_clk_ram->setEnable(mdl_clk_en);

    rewrite(mdl_clk->get(rewriter.wrapper()), mdl_clk_ff, mdl_clk_ram);

    // Rewrite DUT clocks

    for (auto &info : database.user_clocks) {
        auto clk = rewriter.clock(info.top_name);

        if (info.ff_clk.empty()) {
            info.ff_clk = clk->name() + "_ff";
            rewriter.define_clock(info.ff_clk);
        }

        if (info.ram_clk.empty()) {
            info.ram_clk = clk->name() + "_ram";
            rewriter.define_clock(info.ram_clk);
        }

        auto ff_clk = rewriter.clock(info.ff_clk);
        auto ram_clk = rewriter.clock(info.ram_clk);

        SigBit dut_clk_en = clk->getEnable();
        ff_clk->setEnable(dut_clk_en);
        ram_clk->setEnable(dut_clk_en);

        rewrite(clk->get(rewriter.wrapper()), ff_clk, ram_clk);
    }

}

PRIVATE_NAMESPACE_END

void ClockTransform::execute(EmulationDatabase &database, EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing ClockTransform.\n");
    ClockWorker worker(database, rewriter);
    worker.run();
}
