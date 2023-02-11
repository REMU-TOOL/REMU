#include "driver.h"

#include <cstdio>

using namespace REMU;

// Note: trace is not managed by load_checkpoint/save_checkpoint

void Driver::load_checkpoint(uint64_t tick)
{
    fprintf(stderr, "[REMU] INFO: Tick %ld: Loading checkpoint\n", tick);

    auto ckpt = ckpt_mgr.open(tick);
    set_tick_count(tick);

    // Load trace

    auto latest_tick = ckpt_mgr.latest();
    auto latest_ckpt = ckpt_mgr.open(latest_tick);
    trace_db = latest_ckpt.readTrace();

    // Restore signals

    for (auto &signal : om_signal) {
        if (signal.output)
            continue;

        if (trace_db.find(signal.index) == trace_db.end())
            continue;

        auto &sig_data = trace_db.at(signal.index);

        // Find the value at current tick

        auto it = sig_data.lower_bound(tick);
        if (it != sig_data.end() && it->first > tick)
            --it;

        if (it != sig_data.end()) {
            set_signal_value(signal.index, it->second);
        }

        // Restore values after current tick

        for (auto it = sig_data.lower_bound(tick); it != sig_data.end(); ++it) {
            schedule_signal_set(it->first, signal.index, it->second);
        }
    }

    // Load memory regions

    for (auto &axi : om_axi) {
        auto stream = ckpt.readMem(axi.name);
        mem->copy_from_stream(axi.assigned_offset, axi.assigned_size, stream);
    }

    // Load design state

    do_scan(true);

    fprintf(stderr, "[REMU] INFO: Tick %ld: Loaded checkpoint\n", tick);
}

void Driver::save_checkpoint()
{
    uint64_t tick = get_tick_count();

    fprintf(stderr, "[REMU] INFO: Tick %ld: Saving checkpoint\n", tick);

    auto ckpt = ckpt_mgr.open(tick);

    // Save design state

    do_scan(false);

    // Save memory regions

    for (auto &axi : om_axi) {
        auto stream = ckpt.writeMem(axi.name);
        mem->copy_to_stream(axi.assigned_offset, axi.assigned_size, stream);
    }

    // Save trace

    ckpt.writeTrace(trace_db);

    fprintf(stderr, "[REMU] INFO: Tick %ld: Saved checkpoint\n", tick);
}
