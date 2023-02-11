#ifndef _REMU_DRIVER_H_
#define _REMU_DRIVER_H_

#include <memory>
#include <vector>
#include <unordered_map>
#include <iostream>

#include "emu_info.h"
#include "signal_info.h"
#include "checkpoint.h"
#include "uma.h"
#include "object.h"
#include "scheduler.h"

namespace REMU {

struct DriverParameters
{
    struct SetSignal
    {
        uint64_t tick;
        std::string name;
        BitVector value;
    };

    std::string ckpt_path;

    bool end_specified;
    uint64_t end;

    bool replay_specified;
    uint64_t replay;

    std::map<std::string, std::string> init_axi_mem;
    std::vector<SetSignal> set_signal;
};

class DriverModel
{
public:

    ~DriverModel() {}
};

class Driver
{
    SysInfo sysinfo;
    PlatInfo platinfo;
    DriverParameters options;

    std::unique_ptr<UserMem> mem;
    std::unique_ptr<UserIO> reg;

    ObjectManager<SignalObject> om_signal;
    ObjectManager<TriggerObject> om_trigger;
    ObjectManager<AXIObject> om_axi;

    Scheduler scheduler;

    std::unordered_map<std::string, std::unique_ptr<DriverModel>> models;
    std::unordered_map<int, std::function<bool(Driver&)>> trigger_callbacks;
    std::vector<std::function<bool(Driver&)>> realtime_callbacks;

    CheckpointManager ckpt_mgr;
    SignalTraceDB trace_db;

    bool running = false;

    void init_uma();
    void init_signal();
    void init_trigger();
    void init_axi();
    void init_model();

    void load_checkpoint();
    void save_checkpoint();

public:

    static void sleep(unsigned int milliseconds);

    bool is_run_mode();
    void enter_run_mode();
    void exit_run_mode();

    bool is_scan_mode();
    void enter_scan_mode();
    void exit_scan_mode();

    uint64_t get_tick_count();
    void set_tick_count(uint64_t count);
    void set_step_count(uint32_t count);

    void do_scan(bool scan_in);

    // Signal

    int lookup_signal(const std::string &name) { return om_signal.lookup(name); }
    std::string get_signal_name(int index) { return om_signal.get(index).name; }

    BitVector get_signal_value(int index);
    void set_signal_value(int index, const BitVector &value);

    // Trigger

    int lookup_trigger(const std::string &name) { return om_trigger.lookup(name); }
    std::string get_trigger_name(int index) { return om_trigger.get(index).name; }

    bool is_trigger_active(int index);
    bool get_trigger_enable(int index);
    void set_trigger_enable(int index, bool enable);
    std::vector<int> get_active_triggers(bool enabled);

    // AXI

    int lookup_axi(const std::string &name) { return om_axi.lookup(name); }
    std::string get_axi_name(int index) { return om_axi.get(index).name; }

    // Control

    bool is_replay_mode() { return options.replay_specified; }

    void schedule_signal_set(uint64_t tick, int index, const BitVector &value)
    {
        if (!is_replay_mode())
            trace_db.trace_data[index][tick] = value;

        scheduler.schedule(tick, [this, index, value]() {
            set_signal_value(index, value);
        });
    }

    void schedule_stop(uint64_t tick)
    {
        scheduler.schedule(tick, [this]() {
            running = false;
        });
    }

    void schedule_periodical_save(uint64_t tick, uint64_t period)
    {
        scheduler.schedule(tick, [this, tick, period]() {
            save_checkpoint();
            schedule_periodical_save(tick + period, period);
        });
    }

    void register_trigger_callback(int index, std::function<bool(Driver&)> callback)
    {
        trigger_callbacks[index] = callback;
    }

    void register_realtime_callback(std::function<bool(Driver&)> callback)
    {
        realtime_callbacks.push_back(callback);
    }

    void main();

    Driver(
        const SysInfo &sysinfo,
        const PlatInfo &platinfo,
        const DriverParameters &options
    )
        : sysinfo(sysinfo), platinfo(platinfo), options(options), ckpt_mgr(options.ckpt_path)
    {
        init_uma();
        init_signal();
        init_trigger();
        init_axi();
        init_model();
    }
};

};

#endif
