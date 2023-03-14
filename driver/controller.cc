#include "controller.h"

#include <cstdio>

#include <stdexcept>
#include <fstream>
#include <functional>

#include "emu_utils.h"
#include "uma_cdma.h"
#include "uma_cosim.h"
#include "uma_devmem.h"
#include "regdef.h"

using namespace REMU;

namespace {

#define FROM_NODE(t, v) auto v = node[#v].as<t>();

const std::unordered_map<std::string,
    std::function<std::unique_ptr<UserMem>(const YAML::Node &)>> mem_type_funcs = {
#ifdef ENABLE_COSIM
    {"cosim",   [](const YAML::Node &node) {
        return std::make_unique<CosimUserMem>();
    }},
#endif
    {"devmem",  [](const YAML::Node &node) {
        FROM_NODE(uint64_t, base)
        FROM_NODE(uint64_t, size)
        FROM_NODE(uint64_t, dma_base)
        return std::make_unique<DMUserMem>(base, size, dma_base);
    }},
    {"cdma",    [](const YAML::Node &node) {
        FROM_NODE(uint64_t, base)
        FROM_NODE(uint64_t, size)
        FROM_NODE(uint64_t, bounce_base)
        FROM_NODE(uint64_t, bounce_size)
        FROM_NODE(uint64_t, cdma_base)
        return std::make_unique<CDMAUserMem>(base, size, bounce_base, bounce_size, cdma_base);
    }},
};

const std::unordered_map<std::string,
    std::function<std::unique_ptr<UserIO>(const YAML::Node &)>> reg_type_funcs = {
#ifdef ENABLE_COSIM
    {"cosim",   [](const YAML::Node &node) {
        return std::make_unique<CosimUserIO>();
    }},
#endif
    {"devmem",  [](const YAML::Node &node) {
        FROM_NODE(uint64_t, base)
        FROM_NODE(uint64_t, size)
        return std::make_unique<DMUserIO>(base, size);
    }},
};

std::unique_ptr<UserMem> create_uma_mem(const YAML::Node &node)
{
    FROM_NODE(std::string, type)

    auto it = mem_type_funcs.find(type);
    if (it == mem_type_funcs.end()) {
        fprintf(stderr, "PlatInfo error: mem type %s is not supported\n", type.c_str());
        throw std::runtime_error("bad platinfo");
    }

    return it->second(node);
}

std::unique_ptr<UserIO> create_uma_reg(const YAML::Node &node)
{
    FROM_NODE(std::string, type)

    auto it = reg_type_funcs.find(type);
    if (it == reg_type_funcs.end()) {
        fprintf(stderr, "PlatInfo error: reg type %s is not supported\n", type.c_str());
        throw std::runtime_error("bad platinfo");
    }

    return it->second(node);
}

#undef FROM_NODE

} // namespace

void Controller::init_uma(const YAML::Node &platinfo)
{
    mem = create_uma_mem(platinfo["mem"]);
    reg = create_uma_reg(platinfo["reg"]);
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
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_PAUSE_BUSY);
    // FIXME: 1 host cycle must be waited to correctly save RAM internal registers
    // Although it should take several cycles to complete reg->read transaction,
    // there is currently no mechanism to guarantee this.
}

bool Controller::is_scan_mode()
{
    return reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_SCAN_MODE;
}

void Controller::enter_scan_mode()
{
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY);
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
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY);

    enter_scan_mode();

    uint32_t scan_ctrl = RegDef::SCAN_CTRL_START;
    if (scan_in)
        scan_ctrl |= RegDef::SCAN_CTRL_DIRECTION;
    reg->write(RegDef::SCAN_CTRL, scan_ctrl);

    while (reg->read(RegDef::SCAN_CTRL) & RegDef::SCAN_CTRL_RUNNING);

    exit_scan_mode();
}

BitVector Controller::get_signal_value(const RTSignal &signal)
{
    int nblks = (signal.width + 31) / 32;
    BitVector res(signal.width);
    for (int i = 0; i < nblks; i++) {
        int offset = i * 32;
        int width = std::min(signal.width - offset, 32);
        res.setValue(offset, width, reg->read(signal.reg_offset + i * 4));
    }
    return res;
}

void Controller::set_signal_value(const RTSignal &signal, const BitVector &value)
{
    if (signal.output)
        return;

    if (value.width() != signal.width)
        throw std::invalid_argument("value width mismatch");

    int nblks = (signal.width + 31) / 32;
    for (int i = 0; i < nblks; i++) {
        int offset = i * 32;
        int width = std::min(signal.width - offset, 32);
        reg->write(signal.reg_offset + i * 4, value.getValue(offset, width));
    }
}

bool Controller::is_trigger_active(const RTTrigger &trigger)
{
    int id = trigger.reg_index;
    int addr = RegDef::TRIG_STAT_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

bool Controller::get_trigger_enable(const RTTrigger &trigger)
{
    int id = trigger.reg_index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

void Controller::set_trigger_enable(const RTTrigger &trigger, bool enable)
{
    int id = trigger.reg_index;
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    if (enable)
        value |= (1 << offset);
    else
        value &= ~(1 << offset);
    reg->write(addr, value);
}

void Controller::configure_axi_range(const RTAXI &axi)
{
    uint64_t base = axi.assigned_base;
    uint64_t mask = axi.assigned_size - 1;
    reg->write(axi.reg_offset + 0x0, base >> 12);
    reg->write(axi.reg_offset + 0x4, mask >> 12);
}
