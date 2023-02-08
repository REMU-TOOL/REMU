#ifndef _REMU_DRIVER_H_
#define _REMU_DRIVER_H_

#include <memory>
#include <map>
#include <queue>

#include "emu_info.h"
#include "bitvector.h"
#include "uma.h"
#include "object.h"
#include "event.h"
#include "signal_trace.h"

namespace REMU {

struct DriverOptions
{
    std::map<std::string, std::string> init_axi_mem;
};

class Callback
{
public:

    virtual void callback(Driver &drv) const = 0;
};

class Driver
{
    SysInfo sysinfo;
    PlatInfo platinfo;
    DriverOptions options;

    std::unique_ptr<UserMem> mem;
    std::unique_ptr<UserIO> reg;

    ObjectManager<SignalObject> om_signal;
    ObjectManager<TriggerObject> om_trigger;
    ObjectManager<AXIObject> om_axi;

    void init_uma();
    void init_signal();
    void init_trigger();
    void init_axi();

    std::priority_queue<EventHolder> event_queue;
    std::map<int, Callback*> trigger_callbacks;

public:

    SignalTraceList signal_trace;

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

    // Scheduling

    void schedule_event(EventHolder event)
    {
        if (event->tick() < get_tick_count())
            throw std::invalid_argument("scheduling event behind current tick");

        event_queue.push(event);
    }

    void register_trigger_callback(int index, Callback *callback)
    {
        trigger_callbacks[index] = callback;
    }

    void unregister_trigger_callback(int index)
    {
        trigger_callbacks.erase(index);
    }

    bool handle_events();

    Driver(
        const SysInfo &sysinfo,
        const PlatInfo &platinfo,
        const DriverOptions &options
    )
        : sysinfo(sysinfo), platinfo(platinfo), options(options)
    {
        init_uma();
        init_signal();
        init_trigger();
        init_axi();
    }
};

};

#endif
