#include "controller.h"

#include <unistd.h>
#include <cstdio>

#include <stdexcept>
#include <fstream>

#include "emu_utils.h"
#include "uma_cosim.h"
#include "uma_devmem.h"
#include "regdef.h"

using namespace REMU;

constexpr uint32_t SLEEP_PERIOD = 10000;

void Controller::sleep()
{
    usleep(SLEEP_PERIOD);
}

void Controller::init_uma(const PlatInfo &platinfo)
{
    if (platinfo.mem_type == "cosim")
        mem = std::unique_ptr<UserMem>(new CosimUserMem(platinfo.mem_base, platinfo.mem_size));
    else if (platinfo.mem_type == "devmem")
        mem = std::unique_ptr<UserMem>(new DMUserMem(platinfo.mem_base, platinfo.mem_size, platinfo.mem_dmabase));
    else {
        fprintf(stderr, "PlatInfo error: mem_type %s is not supported\n", platinfo.mem_type.c_str());
        throw std::runtime_error("bad platinfo");
    }

    if (platinfo.reg_type == "cosim")
        reg = std::unique_ptr<UserIO>(new CosimUserIO(platinfo.reg_base));
    else if (platinfo.reg_type == "devmem")
        reg = std::unique_ptr<UserIO>(new DMUserIO(platinfo.reg_base, platinfo.reg_size));
    else {
        fprintf(stderr, "PlatInfo error: reg_type %s is not supported\n", platinfo.reg_type.c_str());
        throw std::runtime_error("bad platinfo");
    }
}

bool Controller::is_run_mode()
{
    return reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_RUN_MODE;
}

void Controller::enter_run_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl |= RegDef::MODE_CTRL_RUN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

void Controller::exit_run_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl &= ~RegDef::MODE_CTRL_RUN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_PAUSE_BUSY)
       sleep();
    // FIXME: 1 host cycle must be waited to correctly save RAM internal registers
}

bool Controller::is_scan_mode()
{
    return reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_SCAN_MODE;
}

void Controller::enter_scan_mode()
{
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY)
        sleep();
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl |= RegDef::MODE_CTRL_SCAN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

void Controller::exit_scan_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl &= ~RegDef::MODE_CTRL_SCAN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

uint64_t Controller::get_tick_count()
{
    uint32_t lo, hi;
    do {
        hi = reg->read(RegDef::TICK_CNT_HI);
        lo = reg->read(RegDef::TICK_CNT_LO);
    } while (hi != reg->read(RegDef::TICK_CNT_HI));
    return (uint64_t(hi) << 32) | lo;
}

void Controller::set_tick_count(uint64_t count)
{
    reg->write(RegDef::TICK_CNT_LO, count);
    reg->write(RegDef::TICK_CNT_HI, count >> 32);
}

void Controller::set_step_count(uint32_t count)
{
    reg->write(RegDef::STEP_CNT, count);
}

void Controller::do_scan(bool scan_in)
{
    if (is_run_mode() || is_scan_mode())
        throw std::runtime_error("do_scan called in run mode or scan mode");

    // Wait for all models to be in idle state
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY)
        sleep();

    enter_scan_mode();

    uint32_t scan_ctrl = RegDef::SCAN_CTRL_START;
    if (scan_in)
        scan_ctrl |= RegDef::SCAN_CTRL_DIRECTION;
    reg->write(RegDef::SCAN_CTRL, scan_ctrl);

    while (reg->read(RegDef::SCAN_CTRL) & RegDef::SCAN_CTRL_RUNNING)
        sleep();

    exit_scan_mode();
}

void Controller::init_signal(const SysInfo &sysinfo)
{
    for (auto &info : sysinfo.signal) {
        om_signal.add({
            .name           = flatten_name(info.name),
            .width          = info.width,
            .output         = info.output,
            .reg_offset     = info.reg_offset,
        });
    }
    for (auto &signal : om_signal)
        if (!signal.output)
            set_signal_value(signal.index, BitVector(signal.width, 0));
}

BitVector Controller::get_signal_value(int index)
{
    auto &sig = om_signal.get(index);
    int nblks = (sig.width + 31) / 32;
    BitVector res(sig.width);
    for (int i = 0; i < nblks; i++) {
        int offset = i * 32;
        int width = std::min(sig.width - offset, 32);
        res.setValue(offset, width, reg->read(sig.reg_offset + i * 4));
    }
    return res;
}

void Controller::set_signal_value(int index, const BitVector &value)
{
    auto &sig = om_signal.get(index);

    if (sig.output)
        return;

    if (value.width() != sig.width)
        throw std::invalid_argument("value width mismatch");

    int nblks = (sig.width + 31) / 32;
    for (int i = 0; i < nblks; i++) {
        int offset = i * 32;
        int width = std::min(sig.width - offset, 32);
        reg->write(sig.reg_offset + i * 4, value.getValue(offset, width));
    }

#if 0
    auto name = get_signal_name(index);
    fprintf(stderr, "[REMU] INFO: Tick %ld: set signal \"%s\" to %s\n",
        get_tick_count(), name.c_str(), value.bin().c_str());
#endif
}

void Controller::init_trigger(const SysInfo &sysinfo)
{
    for (auto &info : sysinfo.trigger) {
        om_trigger.add({
            .name           = flatten_name(info.name),
            .reg_index      = info.index,
        });
    }
    for (auto &trigger : om_trigger)
        set_trigger_enable(trigger.index, true);
}

bool Controller::is_trigger_active(int index)
{
    int id = om_trigger.get(index).reg_index;
    int addr = RegDef::TRIG_STAT_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

bool Controller::get_trigger_enable(int index)
{
    int id = om_trigger.get(index).reg_index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

void Controller::set_trigger_enable(int index, bool enable)
{
    auto &trig = om_trigger.get(index);
    int id = trig.reg_index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    if (enable)
        value |= (1 << offset);
    else
        value &= ~(1 << offset);
    reg->write(addr, value);
    fprintf(stderr, "[REMU] INFO: Trigger \"%s\" is %s\n",
        trig.name.c_str(), enable ? "enabled" : "disabled");
}

std::vector<int> Controller::get_active_triggers(bool enabled)
{
    std::vector<int> res;
    constexpr int nregs = (RegDef::TRIG_STAT_END - RegDef::TRIG_STAT_START) / 4;
    uint32_t values[nregs];
    for (int i = 0; i < nregs; i++) {
        values[i] = reg->read(RegDef::TRIG_STAT_START + 4*i);
        if (enabled)
            values[i] &= reg->read(RegDef::TRIG_EN_START + 4*i);
    }
    for (auto &trigger : om_trigger) {
        int id = trigger.reg_index;
        if (values[id / 32] & (1 << (id % 32)))
            res.push_back(trigger.index);
    }
    return res;
}

void Controller::init_axi(const SysInfo &sysinfo)
{
    for (auto &info : sysinfo.axi) {
        om_axi.add({
            .name           = flatten_name(info.name),
            .size           = info.size,
            .reg_offset     = info.reg_offset,
            .assigned_offset  = 0,
            .assigned_size  = 0,
        });
    }

    // Allocate memory regions, the largest size first

    std::vector<AXIObject*> sort_list;
    for (auto &axi : om_axi)
        sort_list.push_back(&axi);

    std::sort(sort_list.begin(), sort_list.end(),
        [](AXIObject *a, AXIObject *b) { return a->size > b->size; });

    uint64_t dmabase = mem->dmabase();
    uint64_t alloc_size = 0;
    for (auto p : sort_list) {
        p->assigned_size = 1 << clog2(p->size); // power of 2
        p->assigned_offset = alloc_size;
        alloc_size += p->assigned_size;
        fprintf(stderr, "[REMU] INFO: Allocated memory (offset 0x%08lx - 0x%08lx) for AXI port \"%s\"\n",
            dmabase + p->assigned_offset,
            dmabase + p->assigned_offset + p->assigned_size,
            p->name.c_str());
    }

    if (alloc_size > mem->size()) {
        fprintf(stderr, "[REMU] ERROR: this platform does not have enough device memory (0x%lx actual, 0x%lx required)\n",
            mem->size(), alloc_size);
        throw std::runtime_error("insufficient device memory");
    }

    // Configure AXI remap

    for (auto &axi : om_axi) {
        uint64_t base = dmabase + axi.assigned_offset;
        uint64_t mask = axi.assigned_size - 1;
        reg->write(axi.reg_offset + 0x0, base >>  0);
        reg->write(axi.reg_offset + 0x4, base >> 32);
        reg->write(axi.reg_offset + 0x8, mask >>  0);
        reg->write(axi.reg_offset + 0xc, mask >> 32);
    }

    // Intialize memory

    for (auto &axi : om_axi) {
        fprintf(stderr, "[REMU] INFO: Clearing memory for AXI port \"%s\"\n",
            axi.name.c_str());
        mem->fill(0, axi.assigned_offset, axi.assigned_size);
    }
}
