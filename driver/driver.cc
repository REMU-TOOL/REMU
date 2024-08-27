#include "driver.h"

#include <cstdint>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <algorithm>
#include <chrono>

#include "regdef.h"
#include "uart.h"
#include "emu_utils.h"
#include "sighandler.h"

using namespace REMU;

namespace {

class Profiler
{
    Driver *driver;
    const char *what;
    uint64_t prev_tick;
    std::chrono::steady_clock::time_point prev_time;

public:

    Profiler(Driver *driver, const char *what) :
        driver(driver),
        what(what),
        prev_tick(driver->current_tick()),
        prev_time(std::chrono::steady_clock::now()) {}

    ~Profiler()
    {
        using namespace std::literals;

        auto tick_diff = driver->current_tick() - prev_tick;
        auto time_diff = std::chrono::steady_clock::now() - prev_time;

        fprintf(stderr, "[REMU] INFO: %s: elasped time %.6lfs, rate %.2lf MHz\n", what,
            (std::chrono::duration<double, std::micro>(time_diff) / 1s),
            static_cast<double>(tick_diff) / (time_diff / 1us));
    }
};

};

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
        if(p->size != 0){
            p->assigned_size = 1UL << clog2(p->size); // power of 2
            p->assigned_offset = alloc_size;
        }else{
            p->assigned_size = 0;
            p->assigned_offset = 0;
        }
        alloc_size += p->assigned_size;

        fprintf(stderr, "[REMU] INFO: Allocated memory (offset 0x%08lx - 0x%08lx) for AXI port \"%s\"\n",
            p->assigned_offset,
            p->assigned_offset + p->assigned_size,
            p->name.c_str());

        ctrl.configure_axi_range(*p, dmabase);
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
            uart = std::make_unique<UartModel>(*this, name);

            fprintf(stderr, "[REMU] INFO: UART model \"%s\" loaded\n",
                name.c_str());
        }
        else if (info.type == "rammodel") {
            std::string timing_type = BitVector(info.params.at("TIMING_TYPE")).decode_string();

            if (timing_type == "fixed") {
                rammodel[name] = std::make_unique<RamModelFixed>(*this, name);
            }
            else {
                fprintf(stderr, "[REMU] WARNING: RAM model \"%s\" with unrecognized timing type \"%s\" is ignored\n",
                    name.c_str(), timing_type.c_str());
                continue;
            }

            fprintf(stderr, "[REMU] INFO: RAM model \"%s\" loaded (timing type: %s)\n",
                name.c_str(), timing_type.c_str());
        }
        else {
            fprintf(stderr, "[REMU] WARNING: Model \"%s\" of unrecognized type \"%s\" is ignored\n",
                name.c_str(), info.type.c_str());
        }
    }
}

BitVector Driver::get_signal_value(RTSignal &signal)
{
    return ctrl.get_signal_value(signal);
}

void Driver::set_signal_value(RTSignal &signal, const BitVector &value)
{
    ctrl.set_signal_value(signal, value);
    signal.trace[cur_tick] = value;
}

void Driver::init_trace(const SysInfo &sysinfo)
{
    trace_reg_base = sysinfo.trace[0].reg_offset;
    uint32_t trace_sz = 0;//1024*1024*1024 << trace_sz
    ctrl.configure_trace_range(trace_reg_base, 1 , 0xffffffff);
    ctrl.configure_trace_offset(trace_reg_base, 0);

    for(auto info: sysinfo.trace){
        if (info.type != "uart_tx")
            trace_ports.push_back(info.port_name);
    }
}

void Driver::load_checkpoint()
{
    if (!ckpt_mgr.has_tick(cur_tick)) {
        fprintf(stderr, "[REMU] ERROR: Checkpoint for tick %lu does not exist\n", cur_tick);
        return;
    }

    // Reset perfmon time

    fprintf(stderr, "[REMU] INFO: Start loading checkpoint @ tick %lu\n", cur_tick);

    // Reset meta event queue

    meta_event_q = decltype(meta_event_q)();

    {
        Profiler profiler(this, "load checkpoint total");

        auto ckpt = ckpt_mgr.open(cur_tick);
        ctrl.set_tick_count(cur_tick);

        // Restore signals

        for (auto &signal : signal_db.objects()) {
            if (signal.output)
                continue;

            signal.trace = ckpt_mgr.signal_trace.at(signal.name);

            auto it = signal.trace.upper_bound(cur_tick);
            if (it == signal.trace.begin())
                throw std::runtime_error("failed to find current signal value in trace");

            --it;
            ctrl.set_signal_value(signal, it->second);
        }

        // Load memory regions

        {
            Profiler profiler(this, "load memory");
            for (auto &axi : axi_db.objects()) {
                if(axi.size == 0)
                    continue;
                auto stream = ckpt.axi_mems.at(axi.name).read();
                fprintf(stderr, "[REMU] INFO: Start loading memory at %lx size = %lx\n", axi.assigned_offset, axi.assigned_size);
                ctrl.memory()->copy_from_stream(axi.assigned_offset, axi.assigned_size, stream);
            }
        }

        // Load design state

        {
            Profiler profiler(this, "load design state");
            ctrl.do_scan(true);
        }
    }

    if (is_replay_mode()) {
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
}

void Driver::save_checkpoint()
{
    if (ckpt_mgr.has_tick(cur_tick)) {
        fprintf(stderr, "[REMU] INFO: Tick %lu: Checkpoint already saved, skipping..\n", cur_tick);
        return;
    }

    fprintf(stderr, "[REMU] INFO: Saving checkpoint @ tick %lu\n", cur_tick);

    {
        Profiler profiler(this, "save checkpoint total");

        auto ckpt = ckpt_mgr.open(cur_tick);

        // Save design state

        {
            Profiler profiler(this, "save design state");
            ctrl.do_scan(false);
        }

        // Save memory regions

        {
            Profiler profiler(this, "save memory");
            for (auto &axi : axi_db.objects()) {
                if(axi.size == 0)
                    continue;
                auto stream = ckpt.axi_mems.at(axi.name).write();
                ctrl.memory()->copy_to_stream(axi.assigned_offset, axi.assigned_size, stream);
            }
        }

        // Save signals

        for (auto &signal : signal_db.objects()) {
            if (signal.output)
                continue;

            ckpt_mgr.signal_trace[signal.name] = signal.trace;
        }

        ckpt_mgr.flush();
    }
}

bool Driver::handle_event()
{
    bool stop_requested = false;

    for (int index = 0; index < trigger_db.count(); index++) {
        auto &trigger = trigger_db.object_by_index(index);

        if (!ctrl.get_trigger_enable(trigger) || !ctrl.is_trigger_active(trigger))
            continue;

        fprintf(stderr, "[REMU] INFO: Tick %lu: trigger \"%s\" is activated\n",
            cur_tick, trigger.name.c_str());

        stop_requested = true;
    }

    if(ctrl.get_trace_full()){
        fprintf(stderr, "[REMU] INFO: Tick %lu: trace storage is full\n",
            cur_tick);
        stop_requested = true;
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
            case Ckpt:
                save_checkpoint();
                if (ckpt_interval > 0)
                    meta_event_q.push({cur_tick + ckpt_interval, Ckpt});
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

    // Process meta events

    if (!meta_event_q.empty()) {
        auto &event = meta_event_q.top();
        auto next_tick = event.first;

        if (next_tick < cur_tick)
            throw std::runtime_error("executing event behind current tick");

        step = std::min(step, next_tick - cur_tick);
    }

    // Process trace replay

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

void Driver::save_trace(){
    //TODO:: read trace from trace_base to file
    // use h2c port
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

    if (uart)
        uart->enter_term();

    {
        Profiler profiler(this, "run emulation");
        while (!break_flag) {
            uint32_t step = calc_next_event_step();
            if (step > 0) {
                ctrl.set_step_count(step);
                ctrl.enter_run_mode();
            }

            while (is_running()) {
                if (uart)
                    uart->poll(*this);

                if (break_flag)
                    ctrl.exit_run_mode();
            }

            cur_tick = ctrl.get_tick_count();

            if (handle_event())
                break;
        }
        fprintf(stderr, "\n");
    }

    if (uart)
        uart->exit_term();
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
    init_trace(sysinfo);
}
