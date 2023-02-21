#include "driver.h"

#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <algorithm>

#include "uart.h"
#include "emu_utils.h"

using namespace REMU;

void Driver::init_model()
{
    for (auto &info : sysinfo.model) {
        auto name = flatten_name(info.name);
        if (info.type == "uart") {
            fprintf(stderr, "[REMU] INFO: Model \"%s\" recognized as UART model\n",
                name.c_str());
            models[name] = std::unique_ptr<DriverModel>(new UartModel(*this, name));
        }
        else if (info.type == "rammodel"){
            fprintf(stderr, "[REMU] INFO: Model \"%s\" recognized as RAM model\n",
                name.c_str());
        }
        else {
            fprintf(stderr, "[REMU] WARNING: Model \"%s\" of unrecognized type \"%s\" is ignored\n",
                name.c_str(), info.type.c_str());
        }
    }
}

void Driver::schedule_signal_set(uint64_t tick, int index, const BitVector &value)
{
    if (!is_replay_mode())
        trace_db[index][tick] = value;

    scheduler.schedule(tick, [this, index, value]() {
        ctrl.set_signal_value(index, value);
    });
}

void Driver::schedule_stop(uint64_t tick, std::string reason)
{
    scheduler.schedule(tick, [this, tick, reason]() {
        fprintf(stderr, "[REMU] INFO: Tick %lu: Stop requested, reason: %s\n",
            tick, reason.c_str());
        stop_flag = true;
    });
}

void Driver::schedule_save(uint64_t tick, uint64_t period)
{
    scheduler.schedule(tick, [this, tick, period]() {
        save_checkpoint();
        if (period != 0)
            schedule_save(tick + period, period);
    });
}

void Driver::schedule_print_time(uint64_t tick, uint64_t period)
{
    scheduler.schedule(tick, [this, tick, period]() {
        if (perfmon)
            perfmon->log("interval", tick);
        if (period != 0)
            schedule_print_time(tick + period, period);
    });
}

void Driver::load_checkpoint(uint64_t tick)
{
    fprintf(stderr, "[REMU] INFO: Tick %lu: Loading checkpoint\n", tick);
    if (perfmon)
        perfmon->log("checkpoint load begin", tick);

    scheduler.clear();

    auto ckpt = ckpt_mgr.open(tick);
    ctrl.set_tick_count(tick);

    // Load trace

    auto latest_tick = ckpt_mgr.latest();
    auto latest_ckpt = ckpt_mgr.open(latest_tick);
    trace_db = latest_ckpt.readTrace();

    // Restore signals

    for (auto &signal : ctrl.signals()) {
        if (signal.output)
            continue;

        if (trace_db.find(signal.index) == trace_db.end())
            continue;

        auto &sig_data = trace_db.at(signal.index);

        // Restore values after current tick

        for (auto &it : sig_data) {
            if (it.first >= tick) {
                schedule_signal_set(it.first, signal.index, it.second);
            }
            else {
                ctrl.set_signal_value(signal.index, it.second);
            }
        }

        // Stop at trace end

        schedule_stop(latest_tick, "end of trace");
    }

    // Load memory regions

    if (perfmon)
        perfmon->log("load memory begin", tick);

    for (auto &axi : ctrl.axis()) {
        auto stream = ckpt.readMem(axi.name);
        // FIXME: wrap copy_from_stream in Controller
        ctrl.memory()->copy_from_stream(axi.assigned_offset, axi.assigned_size, stream);
    }

    if (perfmon)
        perfmon->log("load memory end", tick);

    // Load design state

    if (perfmon)
        perfmon->log("scan begin", tick);

    ctrl.do_scan(true);

    if (perfmon)
        perfmon->log("scan end", tick);

    fprintf(stderr, "[REMU] INFO: Tick %lu: Loaded checkpoint\n", tick);
    if (perfmon)
        perfmon->log("checkpoint load end", tick);
}

void Driver::save_checkpoint()
{
    uint64_t tick = current_tick();

    if (ckpt_mgr.exists(tick)) {
        fprintf(stderr, "[REMU] INFO: Tick %lu: Checkpoint already saved, skipping..\n", tick);
        return;
    }

    fprintf(stderr, "[REMU] INFO: Tick %lu: Saving checkpoint\n", tick);
    if (perfmon)
        perfmon->log("checkpoint save begin", tick);

    auto ckpt = ckpt_mgr.open(tick);

    // Save design state

    if (perfmon)
        perfmon->log("scan begin", tick);

    ctrl.do_scan(false);

    if (perfmon)
        perfmon->log("scan end", tick);

    // Save memory regions

    if (perfmon)
        perfmon->log("save memory begin", tick);

    for (auto &axi : ctrl.axis()) {
        auto stream = ckpt.writeMem(axi.name);
        // FIXME: wrap copy_to_stream in Controller
        ctrl.memory()->copy_to_stream(axi.assigned_offset, axi.assigned_size, stream);
    }

    if (perfmon)
        perfmon->log("save memory end", tick);

    // Save trace

    ckpt.writeTrace(trace_db);

    fprintf(stderr, "[REMU] INFO: Tick %lu: Saved checkpoint\n", tick);
    if (perfmon)
        perfmon->log("checkpoint save end", tick);
}

void Driver::process_design_inits()
{
    // Set signals to 0 by default

    for (auto &signal : ctrl.signals()) {
        if (signal.output)
            continue;

        BitVector value(signal.width);
        ctrl.set_signal_value(signal.index, value);
        trace_db[signal.index][0] = value;
    }

    // Process signal initializations

    for (auto &ss : options.set_signal) {
        int index = ctrl.signals().lookup(ss.name);
        if (index < 0) {
            fprintf(stderr, "[REMU] WARNING: Signal \"%s\" specified by --set-signal is not found\n",
                ss.name.c_str());
            continue;
        }

        schedule_signal_set(ss.tick, index, ss.value);
    }

    // Proces AXI memory initializations

    for (auto &kv : options.init_axi_mem) {
        int index = ctrl.axis().lookup(kv.first);
        if (index < 0) {
            fprintf(stderr, "[REMU] WARNING: AXI port \"%s\" specified by --init-axi-mem is not found\n",
                kv.first.c_str());
            continue;
        }
        auto &axi = ctrl.axis().get(index);
        fprintf(stderr, "[REMU] INFO: Initializing memory for AXI port \"%s\" with file \"%s\"\n",
            kv.first.c_str(), kv.second.c_str());
        std::ifstream f(kv.second, std::ios::binary);
        if (f.fail()) {
            fprintf(stderr, "[REMU] ERROR: Can't open file `%s': %s\n", kv.second.c_str(), strerror(errno));
            continue;
        }
        // FIXME: wrap copy_from_stream in Controller
        ctrl.memory()->copy_from_stream(axi.assigned_offset, axi.assigned_size, f);
    }
}

void Driver::handle_triggers()
{
    uint64_t tick = current_tick();

    for (int index : ctrl.get_active_triggers(true)) {
        // If the trigger is handled by a callback, ignore it
        if (trigger_callbacks.count(index) > 0 &&
            trigger_callbacks.at(index)(*this))
            continue;

        auto &trigger = ctrl.triggers().get(index);
        fprintf(stderr, "[REMU] INFO: Tick %lu: trigger \"%s\" is activated\n",
            tick, trigger.name.c_str());

        schedule_stop(tick, "trigger activated");
    }
}

void Driver::handle_pause()
{
    uint64_t tick = current_tick();
    uint64_t step = UINT32_MAX;

    handle_triggers();

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

    if (!stop_flag) {
        ctrl.set_step_count(step);
        ctrl.enter_run_mode();
    }
}

void Driver::main_loop()
{
    fprintf(stderr, "[REMU] INFO: Tick %lu: Start execution\n", current_tick());

    if (options.perf_interval)
        schedule_print_time(0, options.perf_interval);

    stop_flag = false;
    while (true) {
        if (!is_running())
            handle_pause();

        if (stop_flag) {
            // TODO: CLI
            break;
        }

        bool update = false;
        for (auto callback : parallel_callbacks)
            update |= callback(*this);

        if (!update)
            Controller::sleep();
    }

    fprintf(stderr, "[REMU] INFO: Tick %lu: Stop execution\n", current_tick());
}

int Driver::main()
{
    if (options.perf)
        perfmon = std::make_unique<PerfMon>(options.perf_file, 0);

    if (is_replay_mode()) {
        uint64_t ckpt_tick = ckpt_mgr.findNearest(options.replay.value());
        load_checkpoint(ckpt_tick);

        // Disable triggers not handled by models
        for (auto &trigger : ctrl.triggers()) {
            if (trigger_callbacks.find(trigger.index) == trigger_callbacks.end()) {
                ctrl.set_trigger_enable(trigger.index, false);
            }
        }
    }
    else {
        process_design_inits();

        // Checkpoint saving initialization

        // TODO: continue execution in record mode from a specified tick
        ckpt_mgr.clear();
        ctrl.set_tick_count(0);

        schedule_save(0, options.period.value_or(0));
    }

    if (options.to) {
        schedule_stop(options.to.value(), "user specified end time");
    }

    main_loop();

    if (options.save) {
        save_checkpoint();
    }

    return 0;
}
