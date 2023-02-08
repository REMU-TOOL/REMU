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
#include "uma_cosim.h"
#include "uma_devmem.h"

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

void Driver::init_uma()
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
            fprintf(stderr, "[REMU] WARNING: AXI port \"%s\" specified by --init-axi-mem is not found\n",
                kv.first.c_str());
            continue;
        }
        auto &axi = axi_list.at(handle);
        fprintf(stderr, "[REMU] INFO: Initializing memory for AXI port \"%s\" with file \"%s\"\n",
            kv.first.c_str(), kv.second.c_str());
        std::ifstream f(kv.second, std::ios::binary);
        if (f.fail()) {
            fprintf(stderr, "[REMU] ERROR: Can't open file `%s': %s\n", kv.second.c_str(), strerror(errno));
            continue;
        }
        mem->copy_from_stream(axi.assigned_offset, axi.assigned_size, f);
    }
}

bool Driver::is_run_mode()
{
    return reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_RUN_MODE;
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

bool Driver::is_scan_mode()
{
    return reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_SCAN_MODE;
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

void Driver::do_scan(bool scan_in)
{
    if (is_run_mode() || is_scan_mode())
        throw std::runtime_error("do_scan called in run mode or scan mode");

    // Wait for all models to be in idle state
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY)
        sleep(10);

    enter_scan_mode();

    uint32_t scan_ctrl = RegDef::SCAN_CTRL_START;
    if (scan_in)
        scan_ctrl |= RegDef::SCAN_CTRL_DIRECTION;
    reg->write(RegDef::SCAN_CTRL, scan_ctrl);

    while (reg->read(RegDef::SCAN_CTRL) & RegDef::SCAN_CTRL_RUNNING)
        sleep(10);

    exit_scan_mode();
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
    auto &trig = trigger_list.at(handle);
    int id = trig.index;
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

void Driver::sleep(unsigned int milliseconds)
{
    usleep(1000 * milliseconds);
}

int Driver::main()
{
    // test
    printf("driver main\n");
    int rst_handle = lookup_signal("rst");

    printf("tick count: %ld\n", get_tick_count());

    set_signal(rst_handle, BitVector(1, 1));
    set_step_count(10);
    enter_run_mode();
    while (is_run_mode())
        Driver::sleep(100);

    printf("tick count: %ld\n", get_tick_count());

    set_signal(rst_handle, BitVector(1, 0));
    set_step_count(5000);
    enter_run_mode();
    while (is_run_mode())
        Driver::sleep(100);

    printf("tick count: %ld\n", get_tick_count());

    printf("before scan out\n");
    do_scan(false);
    printf("after scan out\n");

    return 0;
}
