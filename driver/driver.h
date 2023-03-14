#ifndef _REMU_DRIVER_H_
#define _REMU_DRIVER_H_

#include <memory>
#include <vector>
#include <unordered_map>
#include <queue>
#include <iostream>
#include <optional>

#include "runtime_data.h"
#include "checkpoint.h"
#include "controller.h"
#include "perfmon.h"

namespace REMU {

struct DriverParameters
{
    std::string ckpt_path;

    bool perf = false;
    std::string perf_file;
    uint64_t perf_interval = 0;
};

class DriverModel
{
public:

    ~DriverModel() {}
};

class Driver
{
    DriverParameters options;
    Controller ctrl;
    CheckpointManager ckpt_mgr;

    RTDatabase<RTSignal> signal_db;
    RTDatabase<RTTrigger> trigger_db;
    RTDatabase<RTAXI> axi_db;

    std::unordered_map<std::string, std::unique_ptr<DriverModel>> models;
    std::vector<std::function<bool(Driver&)>> parallel_callbacks;

    std::unique_ptr<PerfMon> perfmon;

    uint64_t cur_tick = 0;

    enum MetaEventType
    {
        // Priority max
        Stop,
        Perf,
        Ckpt,
        // Priority min
    };

    using MetaEvent = std::pair<uint64_t, MetaEventType>;

    std::priority_queue<MetaEvent, std::vector<MetaEvent>, std::greater<MetaEvent>> meta_event_q;

    uint64_t ckpt_interval = 0;
    uint64_t perf_interval = 0;

    void init_axi(const SysInfo &sysinfo);
    void init_model(const SysInfo &sysinfo);
    void init_perf(const std::string &file, uint64_t interval);

    // immediately change signal value
    void set_signal_value(RTSignal &signal, const BitVector &value);

    void load_checkpoint(bool record);
    void save_checkpoint();

    // -> whether stop is requested
    bool handle_event();

    uint32_t calc_next_event_step();
    void run();

    bool cmd_help       (const std::vector<std::string> &args);
    bool cmd_list       (const std::vector<std::string> &args);
    bool cmd_save       (const std::vector<std::string> &args);
    bool cmd_replay     (const std::vector<std::string> &args);
    bool cmd_record     (const std::vector<std::string> &args);
    bool cmd_run        (const std::vector<std::string> &args);
    bool cmd_trigger    (const std::vector<std::string> &args);
    bool cmd_signal     (const std::vector<std::string> &args);

    static std::unordered_map<std::string, decltype(&Driver::cmd_help)> cmd_dispatcher;

    bool execute_cmd(const std::string &args);
    void run_cli();

public:

    // must be called when paused
    uint64_t current_tick() { return cur_tick; }

    // must be called when paused
    bool is_replay_mode() { return cur_tick < ckpt_mgr.last_tick(); }

    bool is_running() { return ctrl.is_run_mode(); }
    void pause() { ctrl.exit_run_mode(); }

    int lookup_signal(const std::string &name)
    {
        return signal_db.index_by_name(name);
    }

    BitVector get_signal_value(int index);

    // schedule a value change at the specified tick
    void set_signal_value(int index, const BitVector &value, uint64_t tick);

    int lookup_trigger(const std::string &name)
    {
        return trigger_db.index_by_name(name);
    }

    void register_trigger_callback(int index, std::function<bool(Driver&)> callback)
    {
        trigger_db.object_by_index(index).callback = callback;
    }

    void register_parallel_callback(std::function<bool(Driver&)> callback)
    {
        parallel_callbacks.push_back(callback);
    }

    int main();

    Driver(
        const SysInfo &sysinfo,
        const YAML::Node &platinfo,
        const DriverParameters &options
    );
};

};

#endif
