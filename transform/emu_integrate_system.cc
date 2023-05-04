#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "hier.h"
#include "database.h"
#include "emulib.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace REMU;

PRIVATE_NAMESPACE_BEGIN

constexpr uint32_t  CTRL_ADDR_WIDTH         = 16;

constexpr uint32_t  SYS_CTRL_BASE           = 0x0000;
constexpr uint32_t  SYS_CTRL_WIDTH          = 12;

constexpr uint32_t  AXI_REMAP_CFG_BASE      = 0x1000;
constexpr uint32_t  AXI_REMAP_CFG_WIDTH     = 3;
constexpr uint32_t  AXI_REMAP_CFG_LIMIT     = 0x1400;

constexpr uint32_t  SIGNAL_IN_BASE          = 0x2000;
constexpr uint32_t  SIGNAL_IN_WIDTH         = 12;

constexpr uint32_t  SIGNAL_OUT_BASE         = 0x3000;
constexpr uint32_t  SIGNAL_OUT_WIDTH        = 12;

constexpr uint32_t  TRACE_PORT_BASE         = 0x4000;
constexpr uint32_t  TRACE_PORT_WIDTH        = 12;

struct CtrlSig
{
    Wire *wen;
    Wire *waddr;
    Wire *wdata;
    Wire *ren;
    Wire *raddr;
    Wire *rdata;

    void make_internal()
    {
        ::make_internal(wen);
        ::make_internal(waddr);
        ::make_internal(wdata);
        ::make_internal(ren);
        ::make_internal(raddr);
        ::make_internal(rdata);
    }

    CtrlSig clone(Module *module, const std::string &prefix)
    {
        CtrlSig res;
        res.wen = module->addWire("\\" + prefix + "_wen", wen);
        res.waddr = module->addWire("\\" + prefix + "_waddr", waddr);
        res.wdata = module->addWire("\\" + prefix + "_wdata", wdata);
        res.ren = module->addWire("\\" + prefix + "_ren", ren);
        res.raddr = module->addWire("\\" + prefix + "_raddr", raddr);
        res.rdata = module->addWire("\\" + prefix + "_rdata", rdata);
        return res;
    }

    static CtrlSig create(Module *module, const std::string &prefix, int addr_width, int data_width)
    {
        CtrlSig res;
        res.wen = module->addWire("\\" + prefix + "_wen");
        res.waddr = module->addWire("\\" + prefix + "_waddr", addr_width);
        res.wdata = module->addWire("\\" + prefix + "_wdata", data_width);
        res.ren = module->addWire("\\" + prefix + "_ren");
        res.raddr = module->addWire("\\" + prefix + "_raddr", addr_width);
        res.rdata = module->addWire("\\" + prefix + "_rdata", data_width);
        return res;
    }

    static CtrlSig from(Module *module, const std::string &prefix)
    {
        CtrlSig res;
        res.wen = module->wire("\\" + prefix + "_wen");
        res.waddr = module->wire("\\" + prefix + "_waddr");
        res.wdata = module->wire("\\" + prefix + "_wdata");
        res.ren = module->wire("\\" + prefix + "_ren");
        res.raddr = module->wire("\\" + prefix + "_raddr");
        res.rdata = module->wire("\\" + prefix + "_rdata");
        return res;
    }
};

struct CtrlConnBuilder
{
    Module *module;
    CtrlSig master;
    int addr_width;
    int data_width;

    SigSpec wen_list;
    SigSpec waddr_list;
    SigSpec wdata_list;
    SigSpec ren_list;
    SigSpec raddr_list;
    SigSpec rdata_list;
    SigSpec base_list;
    SigSpec mask_list;

    void add(const CtrlSig &slave, uint32_t addr_base, int addr_bits)
    {
        log_assert(GetSize(slave.wen) == 1);
        log_assert(GetSize(slave.wdata) == data_width);
        log_assert(GetSize(slave.ren) == 1);
        log_assert(GetSize(slave.rdata) == data_width);
        log_assert(GetSize(slave.waddr) <= addr_width);
        log_assert(GetSize(slave.waddr) >= addr_bits);
        log_assert(GetSize(slave.raddr) == GetSize(slave.waddr));

        int aw = GetSize(slave.waddr);

        SigSpec waddr = slave.waddr;
        SigSpec raddr = slave.raddr;
        if (aw < addr_width) {
            waddr.append(module->addWire(NEW_ID, addr_width - aw));
            raddr.append(module->addWire(NEW_ID, addr_width - aw));
        }

        wen_list.append(slave.wen);
        waddr_list.append(waddr);
        wdata_list.append(slave.wdata);
        ren_list.append(slave.ren);
        raddr_list.append(raddr);
        rdata_list.append(slave.rdata);

        base_list.append(Const(addr_base, addr_width));
        mask_list.append(Const(0xffffffff << addr_bits, addr_width));
    }

    Cell* emit(IdString cell_name)
    {
        Cell *cell = module->addCell(cell_name, "\\ctrlbus_bridge");

        cell->setParam("\\ADDR_WIDTH", addr_width);
        cell->setParam("\\DATA_WIDTH", data_width);
        cell->setParam("\\M_COUNT", GetSize(wen_list));
        cell->setParam("\\M_BASE_LIST", base_list.as_const());
        cell->setParam("\\M_MASK_LIST", mask_list.as_const());

        cell->setPort("\\s_ctrl_wen", master.wen);
        cell->setPort("\\s_ctrl_waddr", master.waddr);
        cell->setPort("\\s_ctrl_wdata", master.wdata);
        cell->setPort("\\s_ctrl_ren", master.ren);
        cell->setPort("\\s_ctrl_raddr", master.raddr);
        cell->setPort("\\s_ctrl_rdata", master.rdata);

        cell->setPort("\\m_ctrl_wen", wen_list);
        cell->setPort("\\m_ctrl_waddr", waddr_list);
        cell->setPort("\\m_ctrl_wdata", wdata_list);
        cell->setPort("\\m_ctrl_ren", ren_list);
        cell->setPort("\\m_ctrl_raddr", raddr_list);
        cell->setPort("\\m_ctrl_rdata", rdata_list);

        return cell;
    }

    CtrlConnBuilder(Module *module, const CtrlSig &master) :
        module(module),
        master(master),
        addr_width(GetSize(master.waddr)),
        data_width(GetSize(master.wdata))
    {
        log_assert(GetSize(master.raddr) == addr_width);
        log_assert(GetSize(master.rdata) == data_width);
    }
};

void connect_signals(EmulationDatabase &database, Module *top, CtrlConnBuilder &builder)
{
    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *host_rst      = CommonPort::get(top, CommonPort::PORT_HOST_RST);

    SigSpec i_sigs, o_sigs;
    SigSpec i_sig_widths, o_sig_widths;
    int i_idx = 0, o_idx = 0;

    for (auto &info : database.signal_ports) {
        Wire *wire = top->wire("\\" + info.port_name);
        make_internal(wire);

        // pad to multiple of 32
        int nslices = (info.width + 31) / 32;
        int pad_width = nslices * 32 - info.width;
        Wire *pad = top->addWire(NEW_ID, pad_width);
        SigSpec sig({pad, wire});

        if (info.output) {
            o_sigs.append(sig);
            o_sig_widths.append(Const(info.width));
            info.reg_offset = SIGNAL_OUT_BASE + o_idx * 4;
            o_idx += nslices;
        }
        else {
            i_sigs.append(sig);
            i_sig_widths.append(Const(info.width));
            info.reg_offset = SIGNAL_IN_BASE + i_idx * 4;
            i_idx += nslices;
        }
    }

    log_assert(i_idx * 4 < (1<<SIGNAL_IN_WIDTH));
    log_assert(o_idx * 4 < (1<<SIGNAL_OUT_WIDTH));

    if (i_idx > 0) {
        Cell *gpio_o = top->addCell("\\emu_gpio_o", "\\ctrlbus_gpio_out");
        auto ctrl = CtrlSig::create(top, "emu_ctrl_gpio_o", SIGNAL_IN_WIDTH, 32);
        gpio_o->setParam("\\ADDR_WIDTH", Const(SIGNAL_IN_WIDTH));
        gpio_o->setParam("\\DATA_WIDTH", Const(32));
        gpio_o->setParam("\\NREGS", Const(i_idx));
        gpio_o->setParam("\\REG_WIDTH_LIST", i_sig_widths.as_const());
        gpio_o->setPort("\\clk", host_clk);
        gpio_o->setPort("\\rst", host_rst);
        gpio_o->setPort("\\ctrl_wen", ctrl.wen);
        gpio_o->setPort("\\ctrl_waddr", ctrl.waddr);
        gpio_o->setPort("\\ctrl_wdata", ctrl.wdata);
        gpio_o->setPort("\\ctrl_ren", ctrl.ren);
        gpio_o->setPort("\\ctrl_raddr", ctrl.raddr);
        gpio_o->setPort("\\ctrl_rdata", ctrl.rdata);
        gpio_o->setPort("\\gpio_out", i_sigs);
        builder.add(ctrl, SIGNAL_IN_BASE, SIGNAL_IN_WIDTH);
    }

    if (o_idx > 0) {
        Cell *gpio_i = top->addCell("\\emu_gpio_i", "\\ctrlbus_gpio_in");
        auto ctrl = CtrlSig::create(top, "emu_ctrl_gpio_i", SIGNAL_OUT_WIDTH, 32);
        gpio_i->setParam("\\ADDR_WIDTH", Const(SIGNAL_OUT_WIDTH));
        gpio_i->setParam("\\DATA_WIDTH", Const(32));
        gpio_i->setParam("\\NREGS", Const(o_idx));
        gpio_i->setParam("\\REG_WIDTH_LIST", o_sig_widths.as_const());
        gpio_i->setPort("\\clk", host_clk);
        gpio_i->setPort("\\rst", host_rst);
        gpio_i->setPort("\\ctrl_wen", ctrl.wen);
        gpio_i->setPort("\\ctrl_waddr", ctrl.waddr);
        gpio_i->setPort("\\ctrl_wdata", ctrl.wdata);
        gpio_i->setPort("\\ctrl_ren", ctrl.ren);
        gpio_i->setPort("\\ctrl_raddr", ctrl.raddr);
        gpio_i->setPort("\\ctrl_rdata", ctrl.rdata);
        gpio_i->setPort("\\gpio_in", o_sigs);
        builder.add(ctrl, SIGNAL_OUT_BASE, SIGNAL_OUT_WIDTH);
    }
}

void connect_triggers(EmulationDatabase &database, Module *top, Cell *sys_ctrl)
{
    int trig_index = 0;
    SigSpec trigs;
    for (auto &info : database.trigger_ports) {
        Wire *trig = top->wire("\\" + info.port_name);
        make_internal(trig);
        trigs.append(trig);
        info.index = trig_index++;
    }

    log_assert(GetSize(trigs) < 128);

    sys_ctrl->setParam("\\TRIG_COUNT", GetSize(trigs));
    sys_ctrl->setPort("\\trig", trigs);
}

void connect_uart_tx(EmulationDatabase &database, Module *top, Cell *sys_ctrl)
{
    int uart_tx_count = 0;

    for (auto &info : database.trace_ports) {
        if (info.type == "uart_tx") {
            if (uart_tx_count > 0)
                log_error("At most 1 EmuUart instance is allowed\n");

            Wire *valid = top->wire(info.port_valid);
            Wire *ready = top->wire(info.port_ready);
            Wire *data = top->wire(info.port_data);
            make_internal(valid);
            make_internal(ready);
            make_internal(data);

            sys_ctrl->setPort("\\uart_tx_valid",    valid);
            sys_ctrl->setPort("\\uart_tx_ready",    ready);
            sys_ctrl->setPort("\\uart_tx_data",     data);

            uart_tx_count++;
        }
    }
}

void add_axi_remap(EmulationDatabase &database, Module *top, CtrlConnBuilder &builder)
{
    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *host_rst      = CommonPort::get(top, CommonPort::PORT_HOST_RST);

    int i = 0;
    constexpr int step = 1 << AXI_REMAP_CFG_WIDTH;
    constexpr int remap_addr_width = 40;

    for (auto &info : database.axi_ports) {
        IdString araddr_name = "\\" + info.axi.ar.addr.name;
        IdString awaddr_name = "\\" + info.axi.aw.addr.name;
        Wire *araddr = top->wire(araddr_name);
        Wire *awaddr = top->wire(awaddr_name);
        top->rename(araddr, NEW_ID);
        top->rename(awaddr, NEW_ID);
        Wire *new_araddr = top->addWire(araddr_name, remap_addr_width);
        Wire *new_awaddr = top->addWire(awaddr_name, remap_addr_width);
        new_araddr->port_output = true;
        new_awaddr->port_output = true;
        make_internal(araddr);
        make_internal(awaddr);

        auto ctrl = CtrlSig::create(top, stringf("emu_axi_remap_ctrl_%d", i), AXI_REMAP_CFG_WIDTH, 32);
        Cell *cell = top->addCell(stringf("\\emu_remap_%d", i), "\\EmuAXIRemapCtrl");
        cell->setParam("\\CTRL_ADDR_WIDTH", AXI_REMAP_CFG_WIDTH);
        cell->setParam("\\AXI_ADDR_WIDTH", info.axi.addrWidth());
        cell->setPort("\\clk", host_clk);
        cell->setPort("\\rst", host_rst);
        cell->setPort("\\ctrl_wen", ctrl.wen);
        cell->setPort("\\ctrl_waddr", ctrl.waddr);
        cell->setPort("\\ctrl_wdata", ctrl.wdata);
        cell->setPort("\\ctrl_ren", ctrl.ren);
        cell->setPort("\\ctrl_raddr", ctrl.raddr);
        cell->setPort("\\ctrl_rdata", ctrl.rdata);
        cell->setPort("\\araddr_i", araddr);
        cell->setPort("\\araddr_o", new_araddr);
        cell->setPort("\\awaddr_i", awaddr);
        cell->setPort("\\awaddr_o", new_awaddr);

        info.reg_offset = AXI_REMAP_CFG_BASE + step * i;
        if (info.reg_offset >= AXI_REMAP_CFG_LIMIT)
            log_error("too many AXI interfaces\n");

        builder.add(ctrl, info.reg_offset, AXI_REMAP_CFG_WIDTH);
        i++;
    }

    log_assert(AXI_REMAP_CFG_BASE + step * i < AXI_REMAP_CFG_LIMIT);
}

struct SystemTransform
{
    Yosys::Design *design;
    EmulationDatabase &database;
    EmuLibInfo &emulib;

    void run();

    SystemTransform(Yosys::Design *design, EmulationDatabase &database, EmuLibInfo &emulib)
        : design(design), database(database), emulib(emulib) {}
};

void SystemTransform::run()
{
    Module *top = design->top_module();

    Wire *host_clk  = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *host_rst  = CommonPort::get(top, CommonPort::PORT_HOST_RST);
    Wire *run_mode  = CommonPort::get(top, CommonPort::PORT_RUN_MODE);
    Wire *scan_mode = CommonPort::get(top, CommonPort::PORT_SCAN_MODE);
    Wire *idle      = CommonPort::get(top, CommonPort::PORT_IDLE);
    Wire *ff_se     = CommonPort::get(top, CommonPort::PORT_FF_SE);
    Wire *ff_di     = CommonPort::get(top, CommonPort::PORT_FF_DI);
    Wire *ff_do     = CommonPort::get(top, CommonPort::PORT_FF_DO);
    Wire *ram_sr    = CommonPort::get(top, CommonPort::PORT_RAM_SR);
    Wire *ram_se    = CommonPort::get(top, CommonPort::PORT_RAM_SE);
    Wire *ram_sd    = CommonPort::get(top, CommonPort::PORT_RAM_SD);
    Wire *ram_di    = CommonPort::get(top, CommonPort::PORT_RAM_DI);
    Wire *ram_do    = CommonPort::get(top, CommonPort::PORT_RAM_DO);

    make_internal(run_mode);
    make_internal(scan_mode);
    make_internal(idle);
    make_internal(ff_se);
    make_internal(ff_di);
    make_internal(ff_do);
    make_internal(ram_sr);
    make_internal(ram_se);
    make_internal(ram_sd);
    make_internal(ram_di);
    make_internal(ram_do);

    Wire *tick = top->wire("\\EMU_TICK"); // created in FAMETransform
    make_internal(tick);

    // Create AXI lite adapter & interfaces

    Cell *axil_adapter = top->addCell(top->uniquify("\\emu_axil_adapter"), "\\AXILiteToCtrl");
    axil_adapter->setParam("\\ADDR_WIDTH", CTRL_ADDR_WIDTH);
    axil_adapter->setParam("\\DATA_WIDTH", 32);
    axil_adapter->setPort("\\clk", host_clk);
    axil_adapter->setPort("\\rst", host_rst);

    const std::string axil_name = "EMU_CTRL";
    AXI::AXI4 axil(axil_name, AXI::Info(CTRL_ADDR_WIDTH, 32, false, false));
    for (auto &sig : axil.signals()) {
        if (!sig.present())
            continue;
        Wire *wire = top->addWire("\\" + sig.name, sig.width);
        wire->port_input = !sig.output;
        wire->port_output = sig.output;
        std::string postfix = sig.name.substr(axil_name.size());
        axil_adapter->setPort("\\s_axilite" + postfix, wire);
    }

    auto m_ctrl = CtrlSig::create(top, "emu_m_ctrl", CTRL_ADDR_WIDTH, 32);
    axil_adapter->setPort("\\ctrl_wen", m_ctrl.wen);
    axil_adapter->setPort("\\ctrl_waddr", m_ctrl.waddr);
    axil_adapter->setPort("\\ctrl_wdata", m_ctrl.wdata);
    axil_adapter->setPort("\\ctrl_ren", m_ctrl.ren);
    axil_adapter->setPort("\\ctrl_raddr", m_ctrl.raddr);
    axil_adapter->setPort("\\ctrl_rdata", m_ctrl.rdata);

    CtrlConnBuilder builder(top, m_ctrl);

    // Add EmuSysCtrl

    Cell *sys_ctrl = top->addCell(top->uniquify("\\emu_sys_ctrl"), "\\EmuSysCtrl");
    auto sys_ctrl_sig = CtrlSig::create(top, "emu_s_ctrl_sys", 12, 32);
    builder.add(sys_ctrl_sig, SYS_CTRL_BASE, SYS_CTRL_WIDTH);

    sys_ctrl->setPort("\\host_clk",     host_clk);
    sys_ctrl->setPort("\\host_rst",     host_rst);
    sys_ctrl->setPort("\\tick",         tick);
    sys_ctrl->setPort("\\model_busy",   top->Not(NEW_ID, idle));
    sys_ctrl->setPort("\\run_mode",     run_mode);
    sys_ctrl->setPort("\\scan_mode",    scan_mode);

    sys_ctrl->setPort("\\ctrl_wen",     sys_ctrl_sig.wen);
    sys_ctrl->setPort("\\ctrl_waddr",   sys_ctrl_sig.waddr);
    sys_ctrl->setPort("\\ctrl_wdata",   sys_ctrl_sig.wdata);
    sys_ctrl->setPort("\\ctrl_ren",     sys_ctrl_sig.ren);
    sys_ctrl->setPort("\\ctrl_raddr",   sys_ctrl_sig.raddr);
    sys_ctrl->setPort("\\ctrl_rdata",   sys_ctrl_sig.rdata);

    Wire *dma_start = top->addWire(NEW_ID);
    Wire *dma_direction = top->addWire(NEW_ID);
    Wire *dma_running = top->addWire(NEW_ID);

    sys_ctrl->setPort("\\dma_start",        dma_start);
    sys_ctrl->setPort("\\dma_direction",    dma_direction);
    sys_ctrl->setPort("\\dma_running",      dma_running);

    connect_signals(database, top, builder);
    connect_triggers(database, top, sys_ctrl);

    // Add EmuScanCtrl

    Cell *scan_ctrl = top->addCell(top->uniquify("\\emu_scan_ctrl"), "\\EmuScanCtrl");

    uint64_t ff_count = 0;
    for (auto &ff : database.scan_ff)
        ff_count += ff.width;
    scan_ctrl->setParam("\\FF_COUNT", Const(ff_count, 64));

    uint64_t mem_count = 0;
    for (auto &mem : database.scan_ram)
        mem_count += mem.width * mem.depth;
    scan_ctrl->setParam("\\MEM_COUNT", Const(mem_count, 64));

    scan_ctrl->setPort("\\host_clk",        host_clk);
    scan_ctrl->setPort("\\host_rst",        host_rst);
    scan_ctrl->setPort("\\ff_se",           ff_se);
    scan_ctrl->setPort("\\ff_di",           ff_di);
    scan_ctrl->setPort("\\ff_do",           ff_do);
    scan_ctrl->setPort("\\ram_sr",          ram_sr);
    scan_ctrl->setPort("\\ram_se",          ram_se);
    scan_ctrl->setPort("\\ram_sd",          ram_sd);
    scan_ctrl->setPort("\\ram_di",          ram_di);
    scan_ctrl->setPort("\\ram_do",          ram_do);
    scan_ctrl->setPort("\\dma_start",       dma_start);
    scan_ctrl->setPort("\\dma_direction",   dma_direction);
    scan_ctrl->setPort("\\dma_running",     dma_running);

    uint64_t scan_words = (ff_count + 63) / 64 + (mem_count + 63) / 64;
    uint64_t scan_pages = (scan_words * 8 + 0xfff) / 0x1000;

    {
        AXIPort info;
        info.name = {"scanchain"};
        info.port_name = "EMU_SCAN_DMA_AXI";
        info.axi = AXI::AXI4(info.port_name, AXI::Info(40, 64, true, true));
        info.size = scan_pages * 0x1000;
        for (auto &sig : info.axi.signals()) {
            if (!sig.present())
                continue;
            Wire *wire = top->addWire("\\" + sig.name, sig.width);
            wire->port_input = !sig.output;
            wire->port_output = sig.output;
            std::string postfix = sig.name.substr(info.port_name.size());
            scan_ctrl->setPort("\\dma_axi" + postfix, wire);
        }
        database.axi_ports.push_back(std::move(info));
    }

    // Connect UART Tx

    connect_uart_tx(database, top, sys_ctrl);

    // Add AXI remap

    add_axi_remap(database, top, builder);

    // Finalize

    builder.emit(top->uniquify("\\emu_ctrl_bridge"));

    top->fixup_ports();
}

struct EmuIntegrateSystem : public Pass
{
    EmuIntegrateSystem() : Pass("emu_integrate_system", "(REMU internal)") {}

    void execute(vector<string> args, Design* design) override
    {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_INTEGRATE_SYSTEM pass.\n");
        log_push();

        EmuLibInfo emulib(proc_self_dirname() + "../share/remu/emulib/");

        SystemTransform worker(design,
            EmulationDatabase::get_instance(design),
            emulib);

        worker.run();

        log_pop();
    }
} EmuIntegrateSystem;

PRIVATE_NAMESPACE_END
