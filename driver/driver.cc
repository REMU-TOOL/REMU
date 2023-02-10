#include "driver.h"

#include <unistd.h>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <algorithm>
#include <fstream>

#include "emu_utils.h"
#include "regdef.h"
#include "uma_cosim.h"
#include "uma_devmem.h"
#include "uart.h"

using namespace REMU;

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

void Driver::sleep(unsigned int milliseconds)
{
    usleep(1000 * milliseconds);
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
    uint32_t lo, hi;
    do {
        hi = reg->read(RegDef::TICK_CNT_HI);
        lo = reg->read(RegDef::TICK_CNT_LO);
    } while (hi != reg->read(RegDef::TICK_CNT_HI));
    return (uint64_t(hi) << 32) | lo;
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

void Driver::event_loop()
{
    while (true) {
        // If execution is paused, there are possibly events to be handled
        if (!is_run_mode()) {
            uint64_t tick = get_tick_count();
            uint64_t step = UINT32_MAX;
            bool stop = false;

            for (int index : get_active_triggers(true)) {
                // If the trigger is handled by a callback, ignore it
                if (trigger_callbacks.count(index) > 0 &&
                    trigger_callbacks.at(index)(*this))
                    continue;

                auto name = get_trigger_name(index);
                fprintf(stderr, "[REMU] INFO: Tick %ld: trigger \"%s\" is activated\n",
                    tick, name.c_str());
                stop = true;
            }

            while (!event_queue.empty()) {
                auto event = event_queue.top();
                auto event_tick = event->tick();

                if (event_tick < tick)
                    throw std::runtime_error("executing event behind current tick");

                if (event_tick > tick) {
                    step = std::min(step, event_tick - tick);
                    break;
                }

                event_queue.pop();

                if (!event->execute(*this))
                    stop = true;
            }

            if (stop) {
                fprintf(stderr, "[REMU] INFO: Tick %ld: stopped execution\n", tick);
                return;
            }

            set_step_count(step);
            enter_run_mode();
        }

        bool update = false;
        for (auto callback : realtime_callbacks)
            update |= callback(*this);

        if (!update)
            Driver::sleep(10);
    }
}
