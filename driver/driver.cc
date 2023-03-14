#include "driver.h"

#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <algorithm>

#include "uart.h"
#include "emu_utils.h"
#include "sighandler.h"

using namespace REMU;

void Driver::init_axi(const SysInfo &sysinfo)
{
    // Allocate memory regions, the largest size first

    std::vector<RTAXI*> sort_list;
    for (auto &axi : axi_db.objects())
        sort_list.push_back(&axi);

    std::sort(sort_list.begin(), sort_list.end(),
        [](RTAXI *a, RTAXI *b) { return a->size > b->size; });

    auto &mem = ctrl.memory();

    uint64_t dmabase = mem->dmabase();
    uint64_t alloc_size = 0;
    for (auto p : sort_list) {
        p->assigned_size = 1 << clog2(p->size); // power of 2
        p->assigned_base = dmabase + alloc_size;
        alloc_size += p->assigned_size;

        fprintf(stderr, "[REMU] INFO: Allocated memory (offset 0x%08lx - 0x%08lx) for AXI port \"%s\"\n",
            p->assigned_base,
            p->assigned_base + p->assigned_size,
            p->name.c_str());

        ctrl.configure_axi_range(*p);
    }

    if (alloc_size > mem->size()) {
        fprintf(stderr, "[REMU] ERROR: this platform does not have enough device memory (0x%lx actual, 0x%lx required)\n",
            mem->size(), alloc_size);
        throw std::runtime_error("insufficient device memory");
    }
}

void Driver::init_model(const SysInfo &sysinfo)
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

void Driver::init_perf(const std::string &file, uint64_t interval)
{
    perfmon = std::make_unique<PerfMon>(file);
    perf_interval = interval;
}

void Driver::set_signal_value(RTSignal &signal, const BitVector &value)
{
    ctrl.set_signal_value(signal, value);
    signal.trace[cur_tick] = value;
}

BitVector Driver::get_signal_value(int index)
{
    auto &signal = signal_db.object_by_index(index);
    return ctrl.get_signal_value(signal);
}

void Driver::set_signal_value(int index, const BitVector &value, uint64_t tick)
{
    auto &signal = signal_db.object_by_index(index);
    auto &q = signal.pending_changes;

    // Truncate pending value changes
    q.erase(q.lower_bound(tick), q.end());

    q[tick] = value;
}

void Driver::load_checkpoint(bool record)
{
    if (!ckpt_mgr.has_tick(cur_tick)) {
        fprintf(stderr, "[REMU] ERROR: Checkpoint for tick %lu does not exist\n", cur_tick);
        return;
    }

    // Reset perfmon time

    if (perfmon)
        perfmon->reset(cur_tick);

    fprintf(stderr, "[REMU] INFO: Tick %lu: Loading checkpoint\n", cur_tick);
    if (perfmon)
        perfmon->log("checkpoint load begin", cur_tick);

    // Reset meta event queue

    meta_event_q = decltype(meta_event_q)();

    if (record) {
        // Prune checkpoints in record mode
        ckpt_mgr.truncate(cur_tick);
    }
    else {
        // Setup trace replay queue
        for (auto &signal : signal_db.objects()) {
            if (signal.output)
                continue;

            signal.trace_replay_q = decltype(signal.trace_replay_q)();
            for (auto it = signal.trace.lower_bound(cur_tick); 
                    it != signal.trace.end(); ++it) {
                signal.trace_replay_q.push(*it);
            }
        }

        // Stop at end of trace in replay mode
        meta_event_q.push({ckpt_mgr.last_tick(), Stop});
    }

    {
        auto ckpt = ckpt_mgr.open(cur_tick);
        ctrl.set_tick_count(cur_tick);

        // Restore signals

        for (auto &signal : signal_db.objects()) {
            if (signal.output)
                continue;

            ctrl.set_signal_value(signal, ckpt.signal_state.at(signal.name));
            signal.trace = ckpt_mgr.signal_trace.at(signal.name);
            signal.pending_changes = ckpt.pending_value_changes.at(signal.name);
        }

        // Load memory regions

        if (perfmon)
            perfmon->log("load memory begin", cur_tick);

        for (auto &axi : axi_db.objects()) {
            auto stream = ckpt.axi_mems.at(axi.name).read();
            ctrl.memory()->copy_from_stream(axi.assigned_base, axi.assigned_size, stream);
        }

        if (perfmon)
            perfmon->log("load memory end", cur_tick);

        // Load design state

        if (perfmon)
            perfmon->log("scan begin", cur_tick);

        ctrl.do_scan(true);

        if (perfmon)
            perfmon->log("scan end", cur_tick);
    }

    fprintf(stderr, "[REMU] INFO: Tick %lu: Loaded checkpoint\n", cur_tick);
    if (perfmon)
        perfmon->log("checkpoint load end", cur_tick);
}

void Driver::save_checkpoint()
{
    if (ckpt_mgr.has_tick(cur_tick)) {
        fprintf(stderr, "[REMU] INFO: Tick %lu: Checkpoint already saved, skipping..\n", cur_tick);
        return;
    }

    fprintf(stderr, "[REMU] INFO: Tick %lu: Saving checkpoint\n", cur_tick);
    if (perfmon)
        perfmon->log("checkpoint save begin", cur_tick);

    {
        auto ckpt = ckpt_mgr.open(cur_tick);

        // Save design state

        if (perfmon)
            perfmon->log("scan begin", cur_tick);

        ctrl.do_scan(false);

        if (perfmon)
            perfmon->log("scan end", cur_tick);

        // Save memory regions

        if (perfmon)
            perfmon->log("save memory begin", cur_tick);

        for (auto &axi : axi_db.objects()) {
            auto stream = ckpt.axi_mems.at(axi.name).write();
            ctrl.memory()->copy_to_stream(axi.assigned_base, axi.assigned_size, stream);
        }

        if (perfmon)
            perfmon->log("save memory end", cur_tick);

        // Save signals

        for (auto &signal : signal_db.objects()) {
            if (signal.output)
                continue;

            ckpt.signal_state[signal.name] = ctrl.get_signal_value(signal);
            ckpt.pending_value_changes[signal.name] = signal.pending_changes;
            ckpt_mgr.signal_trace[signal.name] = signal.trace;
        }
    }

    ckpt_mgr.flush();

    fprintf(stderr, "[REMU] INFO: Tick %lu: Saved checkpoint\n", cur_tick);
    if (perfmon)
        perfmon->log("checkpoint save end", cur_tick);
}

bool Driver::handle_event()
{
    bool stop_requested = false;

    for (auto &trigger : trigger_db.objects()) {
        if (!ctrl.get_trigger_enable(trigger) || !ctrl.is_trigger_active(trigger))
            continue;

        if (perfmon)
            perfmon->incr_triggered_count();

        // If the trigger is handled by a callback, ignore it
        if (trigger.callback && trigger.callback(*this))
            continue;

        fprintf(stderr, "[REMU] INFO: Tick %lu: trigger \"%s\" is activated\n",
            cur_tick, trigger.name.c_str());

        stop_requested = true;
    }

    // Process signal value changes

    for (auto &signal : signal_db.objects()) {
        auto &q = signal.pending_changes;
        while (!q.empty()) {
            auto it = q.begin();
            auto next_tick = it->first;

            if (next_tick > cur_tick)
                break;

            set_signal_value(signal, it->second);

            q.erase(it);
        }
    }

    // Process meta events

    while (!meta_event_q.empty()) {
        auto &event = meta_event_q.top();
        auto next_tick = event.first;

        if (next_tick > cur_tick)
            break;

        switch (event.second) {
            case Stop:
                stop_requested = true;
                break;
            case Perf:
                if (perfmon)
                    perfmon->log("periodical monitoring", cur_tick);
                break;
            case Ckpt:
                save_checkpoint();
                break;
        }

        meta_event_q.pop();
    }

    // Process trace replay

    if (is_replay_mode()) {
        for (auto &signal : signal_db.objects()) {
            auto &q = signal.trace_replay_q;
            while (!q.empty()) {
                auto next_tick = q.front().first;

                if (next_tick > cur_tick)
                    break;

                ctrl.set_signal_value(signal, q.front().second);
                q.pop();
            }
        }
    }

    return stop_requested;
}

uint32_t Driver::calc_next_event_step()
{
    uint64_t step = UINT32_MAX;

    for (auto &signal : signal_db.objects()) {
        auto &q = signal.pending_changes;
        if (q.empty())
            continue;

        auto it = q.begin();
        auto next_tick = it->first;

        if (next_tick < cur_tick)
            throw std::runtime_error("executing event behind current tick");

        step = std::min(step, next_tick - cur_tick);
    }

    if (!meta_event_q.empty()) {
        auto &event = meta_event_q.top();
        auto next_tick = event.first;

        if (next_tick < cur_tick)
            throw std::runtime_error("executing event behind current tick");

        step = std::min(step, next_tick - cur_tick);
    }

    if (is_replay_mode()) {
        for (auto &signal : signal_db.objects()) {
            auto &q = signal.trace_replay_q;
            if (!q.empty()) {
                auto next_tick = q.front().first;

                if (next_tick < cur_tick)
                    throw std::runtime_error("executing event behind current tick");

                step = std::min(step, next_tick - cur_tick);
            }
        }
    }

    return step;
}

void Driver::run()
{
    for (auto &trigger : trigger_db.objects()) {
        ctrl.set_trigger_enable(trigger, trigger.enabled);
    }

    bool break_flag = false;

    SigIntHandler sigint([&break_flag](){
        break_flag = true;
    });

    while (!break_flag) {
        uint32_t step = calc_next_event_step();
        if (step > 0) {
            ctrl.set_step_count(step);
            ctrl.enter_run_mode();
        }

        while (is_running()) {
            for (auto callback : parallel_callbacks)
                callback(*this);

            if (break_flag)
                ctrl.exit_run_mode();
        }

        cur_tick = ctrl.get_tick_count();

        if (handle_event())
            break;
    }
}

int Driver::main()
{
    cur_tick = ckpt_mgr.last_tick();
    load_checkpoint(true);

    run_cli();

    return 0;
}

Driver::Driver(
    const SysInfo &sysinfo,
    const YAML::Node &platinfo,
    const DriverParameters &options
) :
    options(options),
    ckpt_mgr(sysinfo, options.ckpt_path),
    ctrl(sysinfo, platinfo),
    signal_db(sysinfo.signal),
    trigger_db(sysinfo.trigger),
    axi_db(sysinfo.axi)
{
    init_axi(sysinfo);
    init_model(sysinfo);

    if (options.perf)
        init_perf(options.perf_file, options.perf_interval);
}
