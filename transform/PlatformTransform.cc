#include "kernel/yosys.h"
#include "kernel/ff.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

using namespace Emu;

USING_YOSYS_NAMESPACE

PRIVATE_NAMESPACE_BEGIN

class AXILiteSinkNode {

    std::string name;

protected:

    EmulationDatabase &database;
    EmulationRewriter &rewriter;
    Cell *cell;

    friend class AXILiteBridge;

protected:

    AXILiteSinkNode(std::string name, EmulationDatabase &database, EmulationRewriter &rewriter)
        : name(name), database(database), rewriter(rewriter), cell(nullptr) {}

};

// AXILiteBridge uses 12-bit addressing
// high 6 bits are used to address sink nodes
// low 6 bits are for node internal addressing

class AXILiteBridge {

    EmulationDatabase &database;
    EmulationRewriter &rewriter;
    std::vector<Cell *> cells;

public:

    void connect(AXILiteSinkNode &&node) {
        log_assert(node.cell);
        log_assert(cells.size() < 64);
        int address = cells.size();
        cells.push_back(node.cell);
        database.ctrl_addrs[node.name] = address;
    }

    void emit();

    AXILiteBridge(EmulationDatabase &database, EmulationRewriter &rewriter)
        : database(database), rewriter(rewriter) {}

};

struct ScanchainCtrl : public AXILiteSinkNode {
    ScanchainCtrl(EmulationDatabase &database, EmulationRewriter &rewriter);
};

struct PlatformWorker {
    EmulationDatabase &database;
    EmulationRewriter &rewriter;
    void run();
    PlatformWorker(EmulationDatabase &database, EmulationRewriter &rewriter)
        : database(database), rewriter(rewriter) {}
};

void AXILiteBridge::emit()
{
    Module *wrapper = rewriter.wrapper();
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

ScanchainCtrl::ScanchainCtrl(EmulationDatabase &database, EmulationRewriter &rewriter)
    : AXILiteSinkNode("sc_ctrl", database, rewriter)
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

    ff_se   ->make_internal();
    ff_di   ->make_internal();
    ff_do   ->make_internal();
    ram_sr  ->make_internal();
    ram_se  ->make_internal();
    ram_sd  ->make_internal();
    ram_di  ->make_internal();
    ram_do  ->make_internal();

    Module *wrapper = rewriter.wrapper();
    cell = wrapper->addCell("\\sc_ctrl", "\\ScanchainCtrl");

    int ff_count = GetSize(database.scanchain_ff);
    cell->setParam("\\FF_COUNT", Const(ff_count));

    int mem_count = 0;
    for (auto &mem : database.scanchain_ram)
        mem_count += mem.depth;
    cell->setParam("\\MEM_COUNT", Const(mem_count));

    cell->setParam("\\FF_WIDTH", Const(database.ff_width));
    cell->setParam("\\MEM_WIDTH", Const(database.ram_width));

    cell->setPort("\\host_clk", host_clk->get(wrapper));
    cell->setPort("\\host_rst", host_rst->get(wrapper));
    cell->setPort("\\ff_se",    ff_se->get(wrapper));
    cell->setPort("\\ff_di",    ff_di->get(wrapper));
    cell->setPort("\\ff_do",    ff_do->get(wrapper));
    cell->setPort("\\ram_sr",   ram_sr->get(wrapper));
    cell->setPort("\\ram_se",   ram_se->get(wrapper));
    cell->setPort("\\ram_sd",   ram_sd->get(wrapper));
    cell->setPort("\\ram_di",   ram_di->get(wrapper));
    cell->setPort("\\ram_do",   ram_do->get(wrapper));
}

void PlatformWorker::run() {
    AXILiteBridge bridge(database, rewriter);
    bridge.connect(ScanchainCtrl(database, rewriter));
    bridge.emit();
}

PRIVATE_NAMESPACE_END

void PlatformTransform::execute(EmulationDatabase &database, EmulationRewriter &rewriter) {
    log_header(rewriter.design().design(), "Executing PlatformTransform.\n");
    PlatformWorker worker(database, rewriter);
    worker.run();
}
