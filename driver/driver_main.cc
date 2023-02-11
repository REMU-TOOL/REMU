#include "driver.h"

#include <cstdio>
#include <stdexcept>
#include <algorithm>

using namespace REMU;

void Driver::main()
{
    if (is_replay_mode()) {
        trace_db = ckpt_mgr.readTrace();
    }
    else {
        for (auto &ss : options.set_signal) {
            int index = lookup_signal(ss.name);
            if (index < 0) {
                fprintf(stderr, "[REMU] WARNING: Signal \"%s\" specified by --set-signal is not found\n",
                    ss.name.c_str());
                continue;
            }
            schedule_signal_set(ss.tick, index, ss.value);
        }
    }

    if (options.end_specified) {
        schedule_stop(options.end);
    }

    running = true;

    while (true) {
        // If execution is paused, there are possibly events to be handled
        if (!is_run_mode()) {
            uint64_t tick = get_tick_count();
            uint64_t step = UINT32_MAX;

            for (int index : get_active_triggers(true)) {
                // If the trigger is handled by a callback, ignore it
                if (trigger_callbacks.count(index) > 0 &&
                    trigger_callbacks.at(index)(*this))
                    continue;

                auto name = get_trigger_name(index);
                fprintf(stderr, "[REMU] INFO: Tick %ld: trigger \"%s\" is activated\n",
                    tick, name.c_str());
                running = false;
            }

            while (!scheduler.empty()) {
                auto next_tick = scheduler.next_tick();

                if (next_tick < tick)
                    throw std::runtime_error("executing event behind current tick");

                if (next_tick > tick) {
                    step = std::min(step, next_tick - tick);
                    break;
                }

                scheduler.step();
            }

            if (!running) {
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

    if (!is_replay_mode())
        ckpt_mgr.writeTrace(trace_db);
}
