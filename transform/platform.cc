#include "kernel/yosys.h"
#include "kernel/ff.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

// AXILiteBridge uses 12-bit addressing
// high 6 bits are used for sink node addressing
// low 6 bits are for node internal use

class AXILiteBridge {

    Module *wrapper;
    std::vector<Cell *> cells;

public:

    int add_sink(Cell *cell) {
        log_assert(cells.size() < 64);
        cells.push_back(cell);
        return cells.size() - 1;
    }

    void emit();

    AXILiteBridge(Module *wrapper) : wrapper(wrapper) {}

};

struct PlatformWorker {

    EmulationRewriter &rewriter;
    DesignInfo &designinfo;
    EmulationDatabase &database;
    Module *wrapper;
    bool raw;

    AXILiteBridge *bridge;

    void create_sc_ctrl();

    void run();

    PlatformWorker(EmulationRewriter &rewriter, bool raw) :
        rewriter(rewriter),
        designinfo(rewriter.design()),
        database(rewriter.database()),
        wrapper(rewriter.wrapper()),
        raw(raw)
    {
        if (raw)
            bridge = nullptr;
        else
            bridge = new AXILiteBridge(wrapper);
    }

    ~PlatformWorker() {
        if (bridge)
            delete bridge;
    }

};

void AXILiteBridge::emit()
{
    SigSpec rdata_pmux_b, rdata_pmux_s;

    Wire *ctrl_wen    = wrapper->addWire("\\ctrl_wen");
    Wire *ctrl_waddr  = wrapper->addWire("\\ctrl_waddr", 12);
    Wire *ctrl_wdata  = wrapper->addWire("\\ctrl_wdata", 32);
    Wire *ctrl_ren    = wrapper->addWire("\\ctrl_ren");
    Wire *ctrl_raddr  = wrapper->addWire("\\ctrl_raddr", 12);
    Wire *ctrl_rdata  = wrapper->addWire("\\ctrl_rdata", 32);

    int count = 0;
    for (Cell *sink : cells) {
        SigSpec wsel = wrapper->Eq(NEW_ID, SigChunk(ctrl_waddr, 6, 6), Const(count, 8));
        SigSpec wen = wrapper->And(NEW_ID, wsel, ctrl_wen);
        SigSpec rsel = wrapper->Eq(NEW_ID, SigChunk(ctrl_raddr, 6, 6), Const(count, 8));
        SigSpec ren = wrapper->And(NEW_ID, rsel, ctrl_ren);
        SigSpec rdata = wrapper->addWire(NEW_ID, 32);
        sink->setPort("\\ctrl_wen",     wen);
        sink->setPort("\\ctrl_waddr",   SigChunk(ctrl_waddr, 0, 6));
        sink->setPort("\\ctrl_wdata",   ctrl_wdata);
        sink->setPort("\\ctrl_ren",     ren);
        sink->setPort("\\ctrl_raddr",   SigChunk(ctrl_raddr, 0, 6));
        sink->setPort("\\ctrl_rdata",   rdata);
        rdata_pmux_b.append(rdata);
        rdata_pmux_s.append(rsel);
        count++;
    }

    wrapper->addPmux(NEW_ID,
        Const(0, 32), rdata_pmux_b, rdata_pmux_s, ctrl_rdata);

    Cell *cell = wrapper->addCell("\\ctrl_bridge", "\\AXILiteToCtrl");
    cell->setPort("\\ctrl_wen",     ctrl_wen);
    cell->setPort("\\ctrl_waddr",   ctrl_waddr);
    cell->setPort("\\ctrl_wdata",   ctrl_wdata);
    cell->setPort("\\ctrl_ren",     ctrl_ren);
    cell->setPort("\\ctrl_raddr",   ctrl_raddr);
    cell->setPort("\\ctrl_rdata",   ctrl_rdata);
}

void PlatformWorker::create_sc_ctrl()
{
    auto host_clk  = rewriter.wire("host_clk");
    auto host_rst  = rewriter.wire("host_rst");
    auto ff_se     = rewriter.wire("ff_se");
    auto ff_di     = rewriter.wire("ff_di");
    auto ff_do     = rewriter.wire("ff_do");
    auto ram_sr    = rewriter.wire("ram_sr");
    auto ram_se    = rewriter.wire("ram_se");
    auto ram_sd    = rewriter.wire("ram_sd");
    auto ram_di    = rewriter.wire("ram_di");
    auto ram_do    = rewriter.wire("ram_do");

    if (raw) {
        host_clk->make_external(false);
        host_rst->make_external(false);
        ff_se->make_external(false);
        ff_di->make_external(false);
        ff_do->make_external(false);
        ram_sr->make_external(false);
        ram_se->make_external(false);
        ram_sd->make_external(false);
        ram_di->make_external(false);
        ram_do->make_external(false);
    }
    else {
        Cell *sc_ctrl = wrapper->addCell("\\sc_ctrl", "\\ScanchainCtrl");
        sc_ctrl->setPort("\\host_clk", host_clk->get(wrapper));
        sc_ctrl->setPort("\\host_rst", host_rst->get(wrapper));
        sc_ctrl->setPort("\\ff_se", ff_se->get(wrapper));
        sc_ctrl->setPort("\\ff_di", ff_di->get(wrapper));
        sc_ctrl->setPort("\\ff_do", ff_do->get(wrapper));
        sc_ctrl->setPort("\\ram_sr", ram_sr->get(wrapper));
        sc_ctrl->setPort("\\ram_se", ram_se->get(wrapper));
        sc_ctrl->setPort("\\ram_sd", ram_sd->get(wrapper));
        sc_ctrl->setPort("\\ram_di", ram_di->get(wrapper));
        sc_ctrl->setPort("\\ram_do", ram_do->get(wrapper));
        database.scctrl_base = bridge->add_sink(sc_ctrl);
    }
}


void PlatformWorker::run() {
    create_sc_ctrl();
    if (!raw)
        bridge->emit();
}

PRIVATE_NAMESPACE_END

void PlatformTransform::execute(EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing PlatformTransform.\n");
    PlatformWorker worker(rewriter, raw);
    worker.run();
}
