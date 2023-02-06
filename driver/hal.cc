#include "hal.h"

#include <unistd.h>
#include <cstdio>
#include <stdexcept>

#include "regdef.h"

using namespace REMU;

const char * const HAL::mode_str[]  = {
    [PAUSE] = "PAUSE",
    [RUN]   = "RUN",
    [SCAN]  = "SCAN",
};

void HAL::enter_run_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl |= RegDef::MODE_CTRL_RUN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

void HAL::exit_run_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl &= ~RegDef::MODE_CTRL_RUN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_PAUSE_BUSY)
        sleep(10);
    // FIXME: 1 host cycle must be waited to correctly save RAM internal registers
}

void HAL::enter_scan_mode()
{
    while (reg->read(RegDef::MODE_CTRL) & RegDef::MODE_CTRL_MODEL_BUSY)
        sleep(10);
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl |= RegDef::MODE_CTRL_SCAN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

void HAL::exit_scan_mode()
{
    uint32_t mode_ctrl = reg->read(RegDef::MODE_CTRL);
    mode_ctrl &= ~RegDef::MODE_CTRL_SCAN_MODE;
    reg->write(RegDef::MODE_CTRL, mode_ctrl);
}

HAL::Mode HAL::get_mode()
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

void HAL::set_mode(Mode mode)
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

uint64_t HAL::get_tick_count()
{
    uint64_t count = reg->read(RegDef::TICK_CNT_LO);
    count |= uint64_t(reg->read(RegDef::TICK_CNT_HI)) << 32;
    return count;
}

void HAL::set_tick_count(uint64_t count)
{
    reg->write(RegDef::TICK_CNT_LO, count);
    reg->write(RegDef::TICK_CNT_HI, count >> 32);
}

void HAL::set_step_count(uint32_t count)
{
    reg->write(RegDef::STEP_CNT, count);
}

bool HAL::is_trigger_active(int id)
{
    int addr = RegDef::TRIG_STAT_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

bool HAL::get_trigger_enable(int id)
{
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    return value & (1 << offset);
}

void HAL::set_trigger_enable(int id, bool enable)
{
    int addr = RegDef::TRIG_EN_START + (id / 32) * 4;
    int offset = id % 32;
    uint32_t value = reg->read(addr);
    if (enable)
        value |= (1 << offset);
    else
        value &= ~(1 << offset);
    reg->write(addr, value);
}

std::vector<int> HAL::get_active_triggers(bool enabled)
{
    std::vector<int> res;
    constexpr int nregs = (RegDef::TRIG_STAT_END - RegDef::TRIG_STAT_START) / 4;
    for (int i = 0; i < nregs; i++) {
        uint32_t value = reg->read(RegDef::TRIG_STAT_START + 4*i);
        if (enabled)
            value &= reg->read(RegDef::TRIG_EN_START + 4*i);
        for (int j = 0; j < 32; j++) {
            if (value & 1)
                res.push_back(i * 32 + j);
            value >>= 1;
        }
    }
    return res;
}

void HAL::get_signal_value(int reg_offset, int nblks, uint32_t *data)
{
    for (int i = 0; i < nblks; i++)
        data[i] = reg->read(reg_offset + i * 4);
}

void HAL::set_signal_value(int reg_offset, int nblks, uint32_t *data)
{
    for (int i = 0; i < nblks; i++)
        reg->write(reg_offset + i * 4, data[i]);
}

void HAL::sleep(unsigned int milliseconds)
{
    usleep(1000 * milliseconds);
}
