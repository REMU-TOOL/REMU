#include "driver.h"

#include <unistd.h>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <algorithm>
#include <fstream>

#include "emu_utils.h"
#include "escape.h"
#include "regdef.h"

using namespace REMU;

inline std::string flatten_name(const std::vector<std::string> &name)
{
    bool first = true;
    std::stringstream ss;
    for (auto &s : name) {
        if (first)
            first = false;
        else
            ss << ".";
        ss << Escape::escape_verilog_id(s);
    }
    return ss.str();
}

void Driver::init_signal()
{
    for (auto &kv : sysinfo.signal) {
        auto &info = kv.second;
        signal_list.push_back({
            .name           = flatten_name(kv.first),
            .width          = info.width,
            .output         = info.output,
            .reg_offset     = info.reg_offset,
        });
    }
}

void Driver::init_trigger()
{
    for (auto &kv : sysinfo.trigger) {
        auto &info = kv.second;
        trigger_list.push_back({
            .name           = flatten_name(kv.first),
            .index          = info.index,
        });
    }
    for (size_t i = 0; i < trigger_list.size(); i++)
        set_trigger_enable(i, true);
}

void Driver::init_axi()
{
    for (auto &kv : sysinfo.axi) {
        auto &info = kv.second;
        axi_list.push_back({
            .name           = flatten_name(kv.first),
            .size           = info.size,
            .reg_offset     = info.reg_offset,
            .assigned_offset  = 0,
            .assigned_size  = 0,
        });
    }

    // Allocate memory regions, the largest size first

    std::vector<AXIObject*> sort_list;
    for (auto &axi : axi_list)
        sort_list.push_back(&axi);

    std::sort(sort_list.begin(), sort_list.end(),
        [](AXIObject *a, AXIObject *b) { return a->size > b->size; });

    uint64_t dmabase = mem->dmabase();
    uint64_t alloc_size = 0;
    for (auto p : sort_list) {
        p->assigned_size = 1 << clog2(p->size); // power of 2
        p->assigned_offset = alloc_size;
        alloc_size += p->assigned_size;
        fprintf(stderr, "INFO: allocated memory (0x%08lx - 0x%08lx) for AXI port \"%s\"\n",
            dmabase + p->assigned_offset,
            dmabase + p->assigned_offset + p->assigned_size,
            p->name.c_str());
    }

    if (alloc_size > mem->size()) {
        fprintf(stderr, "ERROR: this platform does not have enough device memory (0x%lx actual, 0x%lx required)\n",
            mem->size(), alloc_size);
        throw std::runtime_error("insufficient device memory");
    }

    // Configure AXI remap

    for (auto &axi : axi_list) {
        uint64_t base = dmabase + axi.assigned_offset;
        uint64_t mask = axi.assigned_size - 1;
        reg->write(axi.reg_offset + 0x0, base >>  0);
        reg->write(axi.reg_offset + 0x4, base >> 32);
        reg->write(axi.reg_offset + 0x8, mask >>  0);
        reg->write(axi.reg_offset + 0xc, mask >> 32);
    }

    // Process memory initialization

    for (auto &kv : options.init_axi_mem) {
        int handle = lookup_axi(kv.first);
        if (handle < 0) {
            fprintf(stderr, "WARNING: AXI port \"%s\" specified by --init-axi-mem is not found\n",
                kv.first.c_str());
            continue;
        }
        auto &axi = axi_list.at(handle);
        fprintf(stderr, "INFO: Initializing memory for AXI port \"%s\" with file \"%s\"\n",
            kv.first.c_str(), kv.second.c_str());
        std::ifstream f(kv.second, std::ios::binary);
        if (f.fail()) {
            fprintf(stderr, "ERROR: Can't open file `%s': %s\n", kv.second.c_str(), strerror(errno));
            continue;
        }
        mem->copy_from_stream(axi.assigned_offset, axi.assigned_size, f);
    }
}

void Driver::init_system()
{
    init_signal();
    init_trigger();
    init_axi();
}

void Driver::enter_run_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl |= RegDef::MODE_CTRL_RUN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

void Driver::exit_run_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl &= ~RegDef::MODE_CTRL_RUN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_PAUSE_BUSY)
        sleep(10);
    // FIXME: 1 host cycle must be waited to correctly save RAM internal registers
}

void Driver::enter_scan_mode()
{
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY)
        sleep(10);
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl |= RegDef::MODE_CTRL_SCAN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

void Driver::exit_scan_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl &= ~RegDef::MODE_CTRL_SCAN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

Driver::Mode Driver::get_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    bool run_bit = mode_ctrl & RegDef::MODE_CTRL_RUN_MODE;
    bool scan_bit = mode_ctrl & RegDef::MODE_CTRL_SCAN_MODE;
    if (!run_bit && !scan_bit)
        return Mode::PAUSE;
    if (run_bit && !scan_bit)
        return Mode::RUN;
    if (!run_bit && scan_bit)
        return Mode::SCAN;
    throw std::runtime_error("unknown state");
}

void Driver::set_mode(Mode mode)
{
    Mode prev_mode = get_mode();
    if (prev_mode == mode)
        return;

    switch (prev_mode) {
        case RUN:   exit_run_mode();    break;
        case SCAN:  exit_scan_mode();   break;
    }

    switch (mode) {
        case RUN:   enter_run_mode();   break;
        case SCAN:  enter_scan_mode();  break;
    }
}

uint64_t Driver::get_tick_count()
{
    uint64_t count = reg->read(RegDef::TICK_CNT_LO);
    count |= uint64_t(reg->read(RegDef::TICK_CNT_HI)) << 32;
    return count;
}

void Driver::set_tick_count(uint64_t count)
{
    reg->write(RegDef::TICK_CNT_LO, count);
    reg->write(RegDef::TICK_CNT_HI, count >> 32);
}

void Driver::set_step_count(uint32_t count)
{
    reg->write(RegDef::STEP_CNT, count);
}

BitVector Driver::get_signal(int handle)
{
    auto &sig = signal_list.at(handle);
    int nblks = (sig.width + 31) / 32;
    BitVector res(sig.width);
    for (int i = 0; i < nblks; i++) {
        int offset = i * 32;
        int width = std::min(sig.width - offset, 32);
        res.setValue(offset, width, reg->read(sig.reg_offset + i * 4));
    }
    return res;
}

void Driver::set_signal(int handle, const BitVector &value)
{
    auto &sig = signal_list.at(handle);
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
}

bool Driver::is_trigger_active(int handle)
{
    int id = trigger_list.at(handle).index;
    int addr = RegDef::TRIG_STAT_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

bool Driver::get_trigger_enable(int handle)
{
    int id = trigger_list.at(handle).index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

void Driver::set_trigger_enable(int handle, bool enable)
{
    int id = trigger_list.at(handle).index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    if (enable)
        value |= (1 << offset);
    else
        value &= ~(1 << offset);
    reg->write(addr, value);
}

std::vector<int> Driver::get_active_triggers(bool enabled)
{
    std::vector<int> res;
    constexpr int nregs = (RegDef::TRIG_STAT_END - RegDef::TRIG_STAT_START) / 4;
    uint32_t values[nregs];
    for (int i = 0; i < nregs; i++) {
        values[i] = reg->read(RegDef::TRIG_STAT_START + 4*i);
        if (enabled)
            values[i] &= reg->read(RegDef::TRIG_EN_START + 4*i);
    }
    for (size_t i = 0; i < trigger_list.size(); i++) {
        int id = trigger_list.at(i).index;
        if (values[id / 32] & (1 << (id % 32)))
            res.push_back(i);
    }
    return res;
}

void Driver::do_scan(bool scan_in)
{
    if (get_mode() != Mode::PAUSE)
        throw std::runtime_error("bad do_scan call");

    // Wait for all models to be in idle state
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY)
        sleep(10);

    set_mode(Mode::SCAN);

    uint32_t scan_ctrl = RegDef::SCAN_CTRL_START;
    if (scan_in)
        scan_ctrl |= RegDef::SCAN_CTRL_DIRECTION;
    reg->write(RegDef::SCAN_CTRL, scan_ctrl);

    while (reg->read(RegDef::SCAN_CTRL) & RegDef::SCAN_CTRL_RUNNING)
        sleep(10);

    set_mode(Mode::PAUSE);
}

void Driver::sleep(unsigned int milliseconds)
{
    usleep(1000 * milliseconds);
}
