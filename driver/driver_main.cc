#include "driver.h"

#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <algorithm>

using namespace REMU;

int Driver::main()
{
    if (is_run_mode() || is_scan_mode()) {
        fprintf(stderr, "[REMU] ERROR: Hardware components are in a bad state. Please reconfigure the FPGA.\n");
        return 1;
    }

    if (is_replay_mode()) {
        uint64_t ckpt_tick = ckpt_mgr.findNearest(options.replay);
        load_checkpoint(ckpt_tick);

        // TODO: stop at trace end
    }
    else {

        // Signal initialization

        for (auto &ss : options.set_signal) {
            int index = lookup_signal(ss.name);
            if (index < 0) {
                fprintf(stderr, "[REMU] WARNING: Signal \"%s\" specified by --set-signal is not found\n",
                    ss.name.c_str());
                continue;
            }

            schedule_signal_set(ss.tick, index, ss.value);
        }

        // AXI memory initialization

        for (auto &kv : options.init_axi_mem) {
            int index = om_axi.lookup(kv.first);
            if (index < 0) {
                fprintf(stderr, "[REMU] WARNING: AXI port \"%s\" specified by --init-axi-mem is not found\n",
                    kv.first.c_str());
                continue;
            }
            auto &axi = om_axi.get(index);
            fprintf(stderr, "[REMU] INFO: Initializing memory for AXI port \"%s\" with file \"%s\"\n",
                kv.first.c_str(), kv.second.c_str());
            std::ifstream f(kv.second, std::ios::binary);
            if (f.fail()) {
                fprintf(stderr, "[REMU] ERROR: Can't open file `%s': %s\n", kv.second.c_str(), strerror(errno));
                continue;
            }
            mem->copy_from_stream(axi.assigned_offset, axi.assigned_size, f);
        }

        // Checkpoint saving initialization

        // TODO: continue execution in record mode from a specified tick
        ckpt_mgr.clear();
        set_tick_count(0);

        if (options.period_specified) {
            schedule_periodical_save(0, options.period);
        }
        else {
            save_checkpoint();
        }
    }

    if (options.to_specified) {
        schedule_stop(options.to);
    }

    bool ignore_triggers = false;

    if (is_replay_mode())
        ignore_triggers = true;

    fprintf(stderr, "[REMU] INFO: Tick %ld: Start execution\n", get_tick_count());

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

                //if (!ignore_triggers)
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
                fprintf(stderr, "[REMU] INFO: Tick %ld: Stop execution\n", tick);
                break;
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

    if (!is_replay_mode()) {
        save_checkpoint();
    }

    return 0;
}
