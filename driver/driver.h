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

class Driver;

class EmuModel
{
    std::string name;

public:

    const std::string get_name() const { return name; }

    virtual void save(std::ostream &) const = 0;
    virtual void load(std::istream &) = 0;

    virtual bool handle_realtime_callback(Driver &) { return false; }
    virtual bool handle_trigger_callback(Driver &, int) { return false; }
    virtual bool handle_tick_callback(Driver &, uint64_t) { return false; }

    EmuModel(const std::string &name) : name(name) {}
    virtual ~EmuModel() {}
};

class Driver
{
    DriverParameters options;
    Controller ctrl;
    CheckpointManager ckpt_mgr;

    RTDatabase<RTSignal> signal_db;
    RTDatabase<RTTrigger> trigger_db;
    RTDatabase<RTAXI> axi_db;

    std::unordered_map<std::string, EmuModel*> models;

    std::set<EmuModel*> model_realtime_cbs;
    std::map<int, EmuModel*> model_trigger_cbs;
    std::multimap<uint64_t, EmuModel*> model_tick_cbs; // serializable

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

    BitVector get_signal_value(RTSignal &signal);
    void set_signal_value(RTSignal &signal, const BitVector &value);

    void load_checkpoint();
    void save_checkpoint();

    // -> whether stop is requested
    bool handle_event();

    uint32_t calc_next_event_step();
    void run();

    bool cmd_help           (const std::vector<std::string> &args);
    bool cmd_list           (const std::vector<std::string> &args);
    bool cmd_save           (const std::vector<std::string> &args);
    bool cmd_replay_record  (const std::vector<std::string> &args);
    bool cmd_ckpt_interval  (const std::vector<std::string> &args);
    bool cmd_record         (const std::vector<std::string> &args);
    bool cmd_run            (const std::vector<std::string> &args);
    bool cmd_trigger        (const std::vector<std::string> &args);
    bool cmd_signal         (const std::vector<std::string> &args);

    static std::unordered_map<std::string, decltype(&Driver::cmd_help)> cmd_dispatcher;

    bool execute_cmd(const std::string &args);

public:

    // must be called when paused
    uint64_t current_tick() { return cur_tick; }

    // must be called when paused
    bool is_replay_mode() { return cur_tick < ckpt_mgr.last_tick(); }

    bool is_running() { return ctrl.is_run_mode(); }

    void pause()
    {
        ctrl.exit_run_mode();
        cur_tick = ctrl.get_tick_count();
    }

    int lookup_signal(const std::string &name)
    {
        return signal_db.index_by_name(name);
    }

    BitVector get_signal_value(int index)
    {
        auto &signal = signal_db.object_by_index(index);
        return get_signal_value(signal);
    }

    void set_signal_value(int index, const BitVector &value)
    {
        auto &signal = signal_db.object_by_index(index);
        set_signal_value(signal, value);
    }

    int lookup_trigger(const std::string &name)
    {
        return trigger_db.index_by_name(name);
    }

    void register_realtime_callback(EmuModel *model)
    {
        model_realtime_cbs.insert(model);
    }

    void register_trigger_callback(EmuModel *model, int index)
    {
        if (model_trigger_cbs.find(index) != model_trigger_cbs.end())
            throw std::runtime_error("trigger callback already registered");

        model_trigger_cbs[index] = model;
    }

    void register_tick_callback(EmuModel *model, uint64_t tick)
    {
        model_tick_cbs.insert({tick, model});
    }

    int main(const std::vector<std::string> &commands, bool batch);

    Driver(
        const SysInfo &sysinfo,
        const YAML::Node &platinfo,
        const DriverParameters &options
    );

    ~Driver();
};

};

#endif
