#include "kernel/yosys.h"

#include "attr.h"
#include "port.h"
#include "platform.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

PRIVATE_NAMESPACE_BEGIN

struct CtrlSig
{
    Wire *wen;
    Wire *waddr;
    Wire *wdata;
    Wire *ren;
    Wire *raddr;
    Wire *rdata;
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

const uint32_t  PIPE_INGRESS_PIO_BASE   = 0x00008000u;
const uint32_t  PIPE_INGRESS_PIO_STEP   = 0x00000020u;
const uint32_t  PIPE_INGRESS_PIO_LIMIT  = 0x0000c000u;

const uint32_t  PIPE_EGRESS_PIO_BASE    = 0x0000c000u;
const uint32_t  PIPE_EGRESS_PIO_STEP    = 0x00000020u; // TODO
const uint32_t  PIPE_EGRESS_PIO_LIMIT   = 0x00010000u;

PRIVATE_NAMESPACE_END

void PlatformTransform::connect_main_sigs(Module *top, Cell *emu_ctrl)
{
    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *host_rst      = CommonPort::get(top, CommonPort::PORT_HOST_RST);
    Wire *run_mode      = CommonPort::get(top, CommonPort::PORT_RUN_MODE);
    Wire *scan_mode     = CommonPort::get(top, CommonPort::PORT_SCAN_MODE);
    Wire *idle          = CommonPort::get(top, CommonPort::PORT_IDLE);

    Wire *tick = top->wire("\\EMU_TICK"); // created in FAMETransform

    emu_ctrl->setPort("\\host_clk",     host_clk);
    emu_ctrl->setPort("\\host_rst",     host_rst);
    emu_ctrl->setPort("\\tick",         tick);
    emu_ctrl->setPort("\\model_busy",   top->Not(NEW_ID, idle));
    emu_ctrl->setPort("\\run_mode",     run_mode);
    emu_ctrl->setPort("\\scan_mode",    scan_mode);

    make_internal(run_mode);
    make_internal(scan_mode);
    make_internal(idle);
}

void PlatformTransform::connect_resets(Module *top, Cell *emu_ctrl)
{
    int reset_index = 0;
    SigSpec resets;
    for (auto &info : database.user_resets) {
        Wire *reset = top->wire(info.port_name);
        make_internal(reset);
        resets.append(reset);
        info.index = reset_index++;
    }

    log_assert(GetSize(resets) < 128);

    emu_ctrl->setParam("\\RESET_COUNT", GetSize(resets));
    emu_ctrl->setPort("\\rst", resets);
}

void PlatformTransform::connect_triggers(Module *top, Cell *emu_ctrl)
{
    int trig_index = 0;
    SigSpec trigs;
    for (auto &info : database.user_trigs) {
        Wire *trig = top->wire(info.port_name);
        make_internal(trig);
        trigs.append(trig);
        info.index = trig_index++;
    }

    log_assert(GetSize(trigs) < 128);

    emu_ctrl->setParam("\\TRIG_COUNT", GetSize(trigs));
    emu_ctrl->setPort("\\trig", trigs);
}

void PlatformTransform::connect_pipe_ports(Module *top, Cell *emu_ctrl)
{
    Wire *host_clk      = CommonPort::get(top, CommonPort::PORT_HOST_CLK);
    Wire *host_rst      = CommonPort::get(top, CommonPort::PORT_HOST_RST);

    int source_index = 0, sink_index = 0;

    Wire *source_wen = top->addWire(NEW_ID);
    Wire *source_waddr = top->addWire(NEW_ID, 8);
    Wire *source_wdata = top->addWire(NEW_ID, 32);
    Wire *source_ren = top->addWire(NEW_ID);
    Wire *source_raddr = top->addWire(NEW_ID, 8);
    SigSpec source_rdata = Const(0, 32);
    Wire *sink_wen = top->addWire(NEW_ID);
    Wire *sink_waddr = top->addWire(NEW_ID, 8);
    Wire *sink_wdata = top->addWire(NEW_ID, 32);
    Wire *sink_ren = top->addWire(NEW_ID);
    Wire *sink_raddr = top->addWire(NEW_ID, 8);
    SigSpec sink_rdata = Const(0, 32);

    for (auto &info : database.pipes) {
        if (info.type == "pio") {
            auto wire_valid = top->wire(info.port_valid);
            auto wire_ready = top->wire(info.port_ready);
            auto wire_data = top->wire(info.port_data);
            if (info.output) {
                log_error("TODO");
            }
            else {
                auto wire_empty = top->wire(info.port_empty);

            }
        }
        else if (info.type == "dma") {
            log_error("TODO");
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

void PlatformTransform::connect_scanchain(Module *top, Cell *emu_ctrl)
{
    Wire *ff_se     = CommonPort::get(top, CommonPort::PORT_FF_SE);
    Wire *ff_di     = CommonPort::get(top, CommonPort::PORT_FF_DI);
    Wire *ff_do     = CommonPort::get(top, CommonPort::PORT_FF_DO);
    Wire *ram_sr    = CommonPort::get(top, CommonPort::PORT_RAM_SR);
    Wire *ram_se    = CommonPort::get(top, CommonPort::PORT_RAM_SE);
    Wire *ram_sd    = CommonPort::get(top, CommonPort::PORT_RAM_SD);
    Wire *ram_di    = CommonPort::get(top, CommonPort::PORT_RAM_DI);
    Wire *ram_do    = CommonPort::get(top, CommonPort::PORT_RAM_DO);

    make_internal(ff_se);
    make_internal(ff_di);
    make_internal(ff_do);
    make_internal(ram_sr);
    make_internal(ram_se);
    make_internal(ram_sd);
    make_internal(ram_di);
    make_internal(ram_do);

    int ff_count = 0;
    for (auto &ff : database.ff_list)
        ff_count += ff.width;
    emu_ctrl->setParam("\\FF_COUNT", Const(ff_count));

    int mem_count = 0;
    for (auto &mem : database.ram_list)
        mem_count += mem.width * mem.depth;
    emu_ctrl->setParam("\\MEM_COUNT", Const(mem_count));

    emu_ctrl->setPort("\\ff_se",    ff_se);
    emu_ctrl->setPort("\\ff_di",    ff_di);
    emu_ctrl->setPort("\\ff_do",    ff_do);
    emu_ctrl->setPort("\\ram_sr",   ram_sr);
    emu_ctrl->setPort("\\ram_se",   ram_se);
    emu_ctrl->setPort("\\ram_sd",   ram_sd);
    emu_ctrl->setPort("\\ram_di",   ram_di);
    emu_ctrl->setPort("\\ram_do",   ram_do);
}

void PlatformTransform::run()
{
    Module *top = design->top_module();
    Cell *emu_ctrl = top->addCell(top->uniquify("\\ctrl"), "\\EmuCtrl");

    connect_main_sigs(top, emu_ctrl);
    connect_resets(top, emu_ctrl);
    connect_triggers(top, emu_ctrl);
    connect_pipe_ports(top, emu_ctrl);
    connect_scanchain(top, emu_ctrl);

    top->fixup_ports();

    // Load & parameterize EmuCtrl module in a temporary design to not mess up the original design

    Design *tmp = new Design;

    std::vector<std::string> load_plat_cmd({"read_verilog", "-noautowire", "-lib", "-I", emulib.verilog_include_path});
    load_plat_cmd.insert(load_plat_cmd.end(), emulib.platform_sources.begin(), emulib.platform_sources.end());

    Pass::call(tmp, load_plat_cmd);

    Module *orig_mod = tmp->module(emu_ctrl->type);
    Module *derived_mod = tmp->module(orig_mod->derive(tmp, emu_ctrl->parameters));
    derived_mod->makeblackbox();

    Module *cloned_mod = design->addModule(emu_ctrl->type);
    derived_mod->cloneInto(cloned_mod);

    delete tmp;
}
