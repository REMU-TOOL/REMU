#ifndef _REMU_DRIVER_H_
#define _REMU_DRIVER_H_

#include <memory>
#include <vector>
#include <unordered_map>
#include <iostream>
#include <optional>
#include <chrono>

#include "emu_info.h"
#include "signal_info.h"
#include "checkpoint.h"
#include "controller.h"
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

    // Common options

    std::optional<uint64_t> to;
    bool save = false;

    // Record mode options

    std::map<std::string, std::string> init_axi_mem;
    std::optional<uint64_t> period;
    std::vector<SetSignal> set_signal;

    // Replay mode options

    std::optional<uint64_t> replay;
};

class DriverModel
{
public:

    ~DriverModel() {}
};

struct EmuTimeDiff
{
    std::chrono::nanoseconds timediff;
    int64_t tickdiff;

    double mhz() const
    {
        using namespace std::literals;
        return static_cast<double>(tickdiff) / (timediff / 1us);
    }

    EmuTimeDiff(decltype(timediff) timediff, decltype(tickdiff) tickdiff)
        : timediff(timediff), tickdiff(tickdiff) {}
};

struct EmuTime
{
    std::chrono::time_point<std::chrono::steady_clock> time;
    uint64_t tick;

    EmuTimeDiff operator-(const EmuTime &other) const
    {
        return EmuTimeDiff(
            time - other.time,
            tick - other.tick);
    }

    static EmuTime now(uint64_t tick)
    {
        return EmuTime(std::chrono::steady_clock::now(), tick);
    }

    EmuTime() = default;
    EmuTime(decltype(time) time, decltype(tick) tick)
        : time(time), tick(tick) {}
};

class Driver
{
    SysInfo sysinfo;
    PlatInfo platinfo;
    DriverParameters options;

    Controller ctrl;

    Scheduler scheduler;

    std::unordered_map<std::string, std::unique_ptr<DriverModel>> models;
    std::unordered_map<int, std::function<bool(Driver&)>> trigger_callbacks;
    std::vector<std::function<bool(Driver&)>> parallel_callbacks;

    CheckpointManager ckpt_mgr;
    SignalTraceDB trace_db;

    bool stop_flag = false;

    EmuTime prev_time;
    void diff_and_print_time(uint64_t tick);

    void init_model();

    void process_design_inits();

    void load_checkpoint(uint64_t tick);
    void save_checkpoint();

    void handle_triggers();
    void handle_pause();
    void main_loop();

public:

    uint64_t current_tick() { return ctrl.get_tick_count(); }
    bool is_running() { return ctrl.is_run_mode(); }
    void pause() { ctrl.exit_run_mode(); }

    bool is_replay_mode() { return options.replay.has_value(); }

    int signal_lookup(const std::string &name) { return ctrl.signals().lookup(name); }
    std::string signal_get_name(int index) { return ctrl.signals().get(index).name; }
    BitVector signal_get_value(int index) { return ctrl.get_signal_value(index); }

    int trigger_lookup(const std::string &name) { return ctrl.triggers().lookup(name); }
    std::string trigger_get_name(int index) { return ctrl.triggers().get(index).name; }

    void schedule_signal_set(uint64_t tick, int index, const BitVector &value);
    void schedule_stop(uint64_t tick, std::string reason);
    void schedule_save(uint64_t tick, uint64_t period);
    void schedule_print_time(uint64_t tick, uint64_t period);

    void register_trigger_callback(int index, std::function<bool(Driver&)> callback)
    {
        trigger_callbacks[index] = callback;
    }

    void register_parallel_callback(std::function<bool(Driver&)> callback)
    {
        parallel_callbacks.push_back(callback);
    }

    int main();

    Driver(
        const SysInfo &sysinfo,
        const PlatInfo &platinfo,
        const DriverParameters &options
    ) : sysinfo(sysinfo), platinfo(platinfo), options(options), ckpt_mgr(options.ckpt_path), ctrl(sysinfo, platinfo)
    {
        init_model();
    }
};

};

#endif
