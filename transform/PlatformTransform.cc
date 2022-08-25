#include "kernel/yosys.h"
#include "kernel/ff.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

struct PlatformWorker {
    EmulationDatabase &database;
    EmulationRewriter &rewriter;
    Module *wrapper;
    Cell *emu_ctrl;

    void connect_main_sigs();
    void connect_trigger();
    void connect_reset();
    void connect_scanchain();
    void connect_fifo_ports();
    void run();

    PlatformWorker(EmulationDatabase &database, EmulationRewriter &rewriter) :
        database(database), rewriter(rewriter),
        wrapper(rewriter.wrapper()), emu_ctrl(nullptr) {}
};

void PlatformWorker::connect_main_sigs()
{
    auto host_clk   = rewriter.wire("host_clk");
    auto host_rst   = rewriter.wire("host_rst");
    auto tick       = rewriter.wire("tick");
    auto idle       = rewriter.wire("idle");
    auto run_mode   = rewriter.wire("run_mode");
    auto scan_mode  = rewriter.wire("scan_mode");

    tick        ->make_internal();
    idle        ->make_internal();
    run_mode    ->make_internal();
    scan_mode   ->make_internal();

    emu_ctrl->setPort("\\host_clk",     host_clk->get(wrapper));
    emu_ctrl->setPort("\\host_rst",     host_rst->get(wrapper));
    emu_ctrl->setPort("\\tick",         tick->get(wrapper));
    emu_ctrl->setPort("\\model_busy",   wrapper->Not(NEW_ID, idle->get(wrapper)));
    emu_ctrl->setPort("\\run_mode",     run_mode->get(wrapper));
    emu_ctrl->setPort("\\scan_mode",    scan_mode->get(wrapper));
}

void PlatformWorker::connect_trigger()
{
    int index = 0;
    SigSpec trigs;
    for (auto &info : database.user_trigs) {
        auto trig = rewriter.wire(info.top_name);
        trig->make_internal();
        trigs.append(trig->get(wrapper));
        info.index = index++;
    }

    log_assert(GetSize(trigs) < 128);

    emu_ctrl->setParam("\\TRIG_COUNT", GetSize(trigs));
    emu_ctrl->setPort("\\trig", trigs);
}

void PlatformWorker::connect_reset()
{
    int index = 0;
    SigSpec resets;
    for (auto &info : database.user_resets) {
        auto reset = rewriter.wire(info.top_name);
        reset->make_internal();
        resets.append(reset->get(wrapper));
        info.index = index++;
    }

    log_assert(GetSize(resets) < 128);

    emu_ctrl->setParam("\\RESET_COUNT", GetSize(resets));
    emu_ctrl->setPort("\\rst", resets);
}


void PlatformWorker::connect_scanchain()
{
    auto ff_se     = rewriter.wire("ff_se");
    auto ff_di     = rewriter.wire("ff_di");
    auto ff_do     = rewriter.wire("ff_do");
    auto ram_sr    = rewriter.wire("ram_sr");
    auto ram_se    = rewriter.wire("ram_se");
    auto ram_sd    = rewriter.wire("ram_sd");
    auto ram_di    = rewriter.wire("ram_di");
    auto ram_do    = rewriter.wire("ram_do");

    ff_se   ->make_internal();
    ff_di   ->make_internal();
    ff_do   ->make_internal();
    ram_sr  ->make_internal();
    ram_se  ->make_internal();
    ram_sd  ->make_internal();
    ram_di  ->make_internal();
    ram_do  ->make_internal();

    int ff_count = GetSize(database.scanchain_ff);
    emu_ctrl->setParam("\\FF_COUNT", Const(ff_count));

    int mem_count = 0;
    for (auto &mem : database.scanchain_ram)
        mem_count += mem.depth;
    emu_ctrl->setParam("\\MEM_COUNT", Const(mem_count));

    emu_ctrl->setParam("\\FF_WIDTH", Const(database.ff_width));
    emu_ctrl->setParam("\\MEM_WIDTH", Const(database.ram_width));

    emu_ctrl->setPort("\\ff_se",    ff_se->get(wrapper));
    emu_ctrl->setPort("\\ff_di",    ff_di->get(wrapper));
    emu_ctrl->setPort("\\ff_do",    ff_do->get(wrapper));
    emu_ctrl->setPort("\\ram_sr",   ram_sr->get(wrapper));
    emu_ctrl->setPort("\\ram_se",   ram_se->get(wrapper));
    emu_ctrl->setPort("\\ram_sd",   ram_sd->get(wrapper));
    emu_ctrl->setPort("\\ram_di",   ram_di->get(wrapper));
    emu_ctrl->setPort("\\ram_do",   ram_do->get(wrapper));
}

void PlatformWorker::connect_fifo_ports()
{
    Module *wrapper = rewriter.wrapper();

    int source_index = 0, sink_index = 0;

    Wire *source_wen = wrapper->addWire(NEW_ID);
    Wire *source_waddr = wrapper->addWire(NEW_ID, 8);
    Wire *source_wdata = wrapper->addWire(NEW_ID, 32);
    Wire *source_ren = wrapper->addWire(NEW_ID);
    Wire *source_raddr = wrapper->addWire(NEW_ID, 8);
    SigSpec source_rdata = Const(0, 32);
    Wire *sink_wen = wrapper->addWire(NEW_ID);
    Wire *sink_waddr = wrapper->addWire(NEW_ID, 8);
    Wire *sink_wdata = wrapper->addWire(NEW_ID, 32);
    Wire *sink_ren = wrapper->addWire(NEW_ID);
    Wire *sink_raddr = wrapper->addWire(NEW_ID, 8);
    SigSpec sink_rdata = Const(0, 32);

    for (auto &info : database.fifo_ports) {
        if (info.type == "source") {
            info.index = source_index;
            auto fifo_wen = rewriter.wire(info.port_enable);
            auto fifo_wdata = rewriter.wire(info.port_data);
            auto fifo_wfull = rewriter.wire(info.port_flag);
            fifo_wen->make_internal();
            fifo_wdata->make_internal();
            fifo_wfull->make_internal();

            SigSpec wen, ren;
            int reg_cnt = (info.width + 31) / 32 + 1;
            for (int i=0; i<reg_cnt; i++) {
                wen.append(wrapper->And(NEW_ID, source_wen, wrapper->Eq(NEW_ID, source_waddr, Const(source_index, 8))));
                ren.append(wrapper->And(NEW_ID, source_ren, wrapper->Eq(NEW_ID, source_raddr, Const(source_index, 8))));
                source_index++;
            }

            Wire *rdata = wrapper->addWire(NEW_ID, 32);
            Cell *adapter = wrapper->addCell("\\" + info.top_name + "_adapter", "\\FifoSourceAdapter");
            adapter->setParam("\\DATA_WIDTH", info.width);
            adapter->setPort("\\clk", rewriter.wire("host_clk")->get(wrapper));
            adapter->setPort("\\rst", rewriter.wire("host_rst")->get(wrapper));
            adapter->setPort("\\reg_wen", wen);
            adapter->setPort("\\reg_wdata", source_wdata);
            adapter->setPort("\\reg_ren", ren);
            adapter->setPort("\\reg_rdata", rdata);
            adapter->setPort("\\fifo_wen", fifo_wen->get(wrapper));
            adapter->setPort("\\fifo_wdata", fifo_wdata->get(wrapper));
            adapter->setPort("\\fifo_wfull", fifo_wfull->get(wrapper));
            source_rdata = wrapper->Or(NEW_ID, source_rdata, rdata);
        }
        else if (info.type == "sink") {
            info.index = sink_index;
            auto fifo_ren = rewriter.wire(info.port_enable);
            auto fifo_rdata = rewriter.wire(info.port_data);
            auto fifo_rempty = rewriter.wire(info.port_flag);
            fifo_ren->make_internal();
            fifo_rdata->make_internal();
            fifo_rempty->make_internal();

            SigSpec wen, ren;
            int reg_cnt = (info.width + 31) / 32 + 1;
            for (int i=0; i<reg_cnt; i++) {
                wen.append(wrapper->And(NEW_ID, sink_wen, wrapper->Eq(NEW_ID, sink_waddr, Const(sink_index, 8))));
                ren.append(wrapper->And(NEW_ID, sink_ren, wrapper->Eq(NEW_ID, sink_raddr, Const(sink_index, 8))));
                sink_index++;
            }

            Wire *rdata = wrapper->addWire(NEW_ID, 32);
            Cell *adapter = wrapper->addCell("\\" + info.top_name + "_adapter", "\\FifoSinkAdapter");
            adapter->setParam("\\DATA_WIDTH", info.width);
            adapter->setPort("\\clk", rewriter.wire("host_clk")->get(wrapper));
            adapter->setPort("\\rst", rewriter.wire("host_rst")->get(wrapper));
            adapter->setPort("\\reg_wen", wen);
            adapter->setPort("\\reg_wdata", sink_wdata);
            adapter->setPort("\\reg_ren", ren);
            adapter->setPort("\\reg_rdata", rdata);
            adapter->setPort("\\fifo_ren", fifo_ren->get(wrapper));
            adapter->setPort("\\fifo_rdata", fifo_rdata->get(wrapper));
            adapter->setPort("\\fifo_rempty", fifo_rempty->get(wrapper));
            sink_rdata = wrapper->Or(NEW_ID, sink_rdata, rdata);
        }
    }

    // max 256 regs
    log_assert(source_index < 256);
    log_assert(sink_index < 256);

    emu_ctrl->setPort("\\source_wen",   source_wen);
    emu_ctrl->setPort("\\source_waddr", source_waddr);
    emu_ctrl->setPort("\\source_wdata", source_wdata);
    emu_ctrl->setPort("\\source_ren",   source_ren);
    emu_ctrl->setPort("\\source_raddr", source_raddr);
    emu_ctrl->setPort("\\source_rdata", source_rdata);
    emu_ctrl->setPort("\\sink_wen",     sink_wen);
    emu_ctrl->setPort("\\sink_waddr",   sink_waddr);
    emu_ctrl->setPort("\\sink_wdata",   sink_wdata);
    emu_ctrl->setPort("\\sink_ren",     sink_ren);
    emu_ctrl->setPort("\\sink_raddr",   sink_raddr);
    emu_ctrl->setPort("\\sink_rdata",   sink_rdata);
}

void PlatformWorker::run() {
    emu_ctrl = wrapper->addCell("\\ctrl", "\\EmuCtrl");
    connect_main_sigs();
    connect_trigger();
    connect_reset();
    connect_scanchain();
    connect_fifo_ports();
}

PRIVATE_NAMESPACE_END

void PlatformTransform::execute(EmulationDatabase &database, EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing PlatformTransform.\n");
    PlatformWorker worker(database, rewriter);
    worker.run();
}
