#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "platform.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace REMU;

PRIVATE_NAMESPACE_BEGIN

const uint32_t  CTRL_ADDR_WIDTH         = 16u;

const uint32_t  SYS_CTRL_BASE           = 0x0000u;
const uint32_t  SYS_CTRL_WIDTH          = 12u;

const uint32_t  AXI_REMAP_CFG_BASE      = 0x1600u;
const uint32_t  AXI_REMAP_CFG_WIDTH     = 4u;
const uint32_t  AXI_REMAP_CFG_LIMIT     = 0x1800u;

const uint32_t  PIPE_INGRESS_PIO_BASE   = 0x1800u;
const uint32_t  PIPE_INGRESS_PIO_WIDTH  = 5u;
const uint32_t  PIPE_INGRESS_PIO_LIMIT  = 0x1c00u;

const uint32_t  PIPE_EGRESS_PIO_BASE    = 0x1c00u;
const uint32_t  PIPE_EGRESS_PIO_WIDTH   = 3u;
const uint32_t  PIPE_EGRESS_PIO_LIMIT   = 0x2000u;

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
        log_assert(GetSize(slave.waddr) == addr_width);
        log_assert(GetSize(slave.wdata) == data_width);
        log_assert(GetSize(slave.ren) == 1);
        log_assert(GetSize(slave.raddr) == addr_width);
        log_assert(GetSize(slave.rdata) == data_width);

        wen_list.append(slave.wen);
        waddr_list.append(slave.waddr);
        wdata_list.append(slave.wdata);
        ren_list.append(slave.ren);
        raddr_list.append(slave.raddr);
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

void connect_resets(EmulationDatabase &database, Module *top, Cell *sys_ctrl)
{
    int reset_index = 0;
    SigSpec resets;
    for (auto &info : database.user_resets) {
        Wire *reset = top->wire("\\" + info.port_name);
        make_internal(reset);
        resets.append(reset);
        info.index = reset_index++;
    }

    log_assert(GetSize(resets) < 128);

    sys_ctrl->setParam("\\RESET_COUNT", GetSize(resets));
    sys_ctrl->setPort("\\rst", resets);
}

void connect_triggers(EmulationDatabase &database, Module *top, Cell *sys_ctrl)
{
    int trig_index = 0;
    SigSpec trigs;
    for (auto &info : database.user_trigs) {
        Wire *trig = top->wire("\\" + info.port_name);
        make_internal(trig);
        trigs.append(trig);
        info.index = trig_index++;
    }

    log_assert(GetSize(trigs) < 128);

    sys_ctrl->setParam("\\TRIG_COUNT", GetSize(trigs));
    sys_ctrl->setPort("\\trig", trigs);
}

void add_axi_remap(EmulationDatabase &database, Module *top, CtrlConnBuilder &builder)
{
    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *host_rst      = CommonPort::get(top, CommonPort::PORT_HOST_RST);

    int i = 0;
    const unsigned int step = 1 << AXI_REMAP_CFG_WIDTH;

    for (auto &info : database.axi_intfs) {
        IdString araddr_name = "\\" + info.axi.ar.addr.name;
        IdString awaddr_name = "\\" + info.axi.aw.addr.name;
        Wire *araddr = top->wire(araddr_name);
        Wire *awaddr = top->wire(awaddr_name);
        top->rename(araddr, NEW_ID);
        top->rename(awaddr, NEW_ID);
        Wire *new_araddr = top->addWire(araddr_name, araddr);
        Wire *new_awaddr = top->addWire(awaddr_name, awaddr);
        make_internal(araddr);
        make_internal(awaddr);

        auto ctrl = CtrlSig::create(top, stringf("emu_axi_remap_ctrl_%d", i), CTRL_ADDR_WIDTH, 32);
        Cell *cell = top->addCell(stringf("\\emu_remap_%d", i), "\\EmuAXIRemapCtrl");
        cell->setParam("\\CTRL_ADDR_WIDTH", CTRL_ADDR_WIDTH);
        cell->setParam("\\ADDR_WIDTH", info.axi.addrWidth());
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
}

void add_pipe_adapters(EmulationDatabase &database, Module *top, CtrlConnBuilder &builder)
{
    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *host_rst      = CommonPort::get(top, CommonPort::PORT_HOST_RST);

    int i_pio_idx = 0;
    int e_pio_idx = 0;

    const unsigned int i_pio_step = 1 << PIPE_INGRESS_PIO_WIDTH;
    const unsigned int e_pio_step = 1 << PIPE_EGRESS_PIO_WIDTH;

    for (auto &info : database.pipes) {
        auto name = join_string(info.name, '_');
        auto ctrl = CtrlSig::create(top, "emu_ctrl_" + name, CTRL_ADDR_WIDTH, 32);
        if (info.type == "pio") {
            Cell *cell = top->addCell("\\emu_pipe_adapter_" + name,
                info.output ? "\\EgressPipePIOAdapter" : "\\IngressPipePIOAdapter");

            cell->setParam("\\CTRL_ADDR_WIDTH", CTRL_ADDR_WIDTH);
            cell->setParam("\\DATA_WIDTH", info.width);
            cell->setParam("\\FIFO_DEPTH", 16); // TODO: specified by user
            cell->setPort("\\clk", host_clk);
            cell->setPort("\\rst", host_rst);
            cell->setPort("\\ctrl_wen", ctrl.wen);
            cell->setPort("\\ctrl_waddr", ctrl.waddr);
            cell->setPort("\\ctrl_wdata", ctrl.wdata);
            cell->setPort("\\ctrl_ren", ctrl.ren);
            cell->setPort("\\ctrl_raddr", ctrl.raddr);
            cell->setPort("\\ctrl_rdata", ctrl.rdata);

            auto wire_valid = top->wire(info.port_valid);
            auto wire_ready = top->wire(info.port_ready);
            auto wire_data = top->wire(info.port_data);
            cell->setPort("\\stream_valid", wire_valid);
            cell->setPort("\\stream_ready", wire_ready);
            cell->setPort("\\stream_data", wire_data);

            if (!info.output) {
                auto wire_empty = top->wire(info.port_empty);
                cell->setPort("\\stream_empty", wire_empty);
                info.reg_offset = PIPE_INGRESS_PIO_BASE + i_pio_step * i_pio_idx;
                if (info.reg_offset >= PIPE_INGRESS_PIO_LIMIT)
                    log_error("too many ingress pipes\n");
                builder.add(ctrl, info.reg_offset, PIPE_INGRESS_PIO_WIDTH);
                i_pio_idx++;
            }
            else {
                info.reg_offset = PIPE_EGRESS_PIO_BASE + e_pio_step * e_pio_idx;
                if (info.reg_offset >= PIPE_EGRESS_PIO_LIMIT)
                    log_error("too many egress pipes\n");
                builder.add(ctrl, info.reg_offset, PIPE_EGRESS_PIO_WIDTH);
                e_pio_idx++;
            }
        }
        else if (info.type == "dma") {
            log_error("TODO");
        }
    }
}

PRIVATE_NAMESPACE_END

void PlatformTransform::run()
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
    auto sys_ctrl_sig = CtrlSig::create(top, "emu_s_ctrl_sys", CTRL_ADDR_WIDTH, 32);
    builder.add(sys_ctrl_sig, SYS_CTRL_BASE, SYS_CTRL_WIDTH);

    sys_ctrl->setParam("\\CTRL_ADDR_WIDTH", CTRL_ADDR_WIDTH);

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

    Wire *dma_base = top->addWire(NEW_ID, 32);
    Wire *dma_start = top->addWire(NEW_ID);
    Wire *dma_direction = top->addWire(NEW_ID);
    Wire *dma_running = top->addWire(NEW_ID);

    sys_ctrl->setPort("\\dma_base",         dma_base);
    sys_ctrl->setPort("\\dma_start",        dma_start);
    sys_ctrl->setPort("\\dma_direction",    dma_direction);
    sys_ctrl->setPort("\\dma_running",      dma_running);

    connect_resets(database, top, sys_ctrl);
    connect_triggers(database, top, sys_ctrl);

    // Add EmuScanCtrl

    Cell *scan_ctrl = top->addCell(top->uniquify("\\emu_scan_ctrl"), "\\EmuScanCtrl");

    int ff_count = 0;
    for (auto &ff : database.ff_list)
        ff_count += ff.width;
    scan_ctrl->setParam("\\FF_COUNT", Const(ff_count));

    int mem_count = 0;
    for (auto &mem : database.ram_list)
        mem_count += mem.width * mem.depth;
    scan_ctrl->setParam("\\MEM_COUNT", Const(mem_count));

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
    scan_ctrl->setPort("\\dma_base",        dma_base);
    scan_ctrl->setPort("\\dma_start",       dma_start);
    scan_ctrl->setPort("\\dma_direction",   dma_direction);
    scan_ctrl->setPort("\\dma_running",     dma_running);

    const std::string dma_axi_name = "EMU_SCAN_DMA_AXI";
    AXI::AXI4 dma_axi(dma_axi_name, AXI::Info(32, 64, true, true));
    for (auto &sig : dma_axi.signals()) {
        if (!sig.present())
            continue;
        Wire *wire = top->addWire("\\" + sig.name, sig.width);
        wire->port_input = !sig.output;
        wire->port_output = sig.output;
        std::string postfix = sig.name.substr(dma_axi_name.size());
        scan_ctrl->setPort("\\dma_axi" + postfix, wire);
    }

    // Add AXI remap

    add_axi_remap(database, top, builder);

    // Add pipe adapters

    add_pipe_adapters(database, top, builder);

    // Finalize

    builder.emit(top->uniquify("\\emu_ctrl_bridge"));

    top->fixup_ports();
}
