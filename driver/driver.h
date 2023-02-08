#ifndef _REMU_DRIVER_H_
#define _REMU_DRIVER_H_

#include <memory>
#include <map>
#include <queue>

#include "emu_info.h"
#include "bitvector.h"
#include "uma.h"

namespace REMU {

class Driver;

class Event
{
    uint64_t m_tick;

public:

    uint64_t tick() const { return m_tick; }
    bool operator<(const Event &other) const { return m_tick > other.m_tick; }
    virtual void execute(Driver &drv) const = 0;

    Event(uint64_t tick) : m_tick(tick) {}
    virtual ~Event() {}
};

class EventHolder
{
    std::unique_ptr<Event> event;

public:

    Event& operator*() const { return *event; }
    Event* operator->() const { return event.get(); }
    bool operator<(const EventHolder &other) const { return *event < *other.event; }

    EventHolder(Event *event) : event(event) {}
};

class BreakEvent : public Event
{
public:

    virtual void execute(Driver &drv) const override;

    BreakEvent(uint64_t tick) : Event(tick) {}
};

class SignalEvent : public Event
{
    int index;
    BitVector value;

public:

    virtual void execute(Driver &drv) const override;

    SignalEvent(uint64_t tick, int index, const BitVector &value) :
        Event(tick), index(index), value(value) {}
};

class Callback
{
public:

    virtual void execute(Driver &drv) const = 0;
};

struct DriverOptions
{
    std::map<std::string, std::string> init_axi_mem;
};

class Driver
{
    SysInfo sysinfo;
    PlatInfo platinfo;
    DriverOptions options;

    std::unique_ptr<UserMem> mem;
    std::unique_ptr<UserIO> reg;

    struct SignalObject
    {
        std::string name;
        int width;
        bool output;
        uint32_t reg_offset;
    };

    struct TriggerObject
    {
        std::string name;
        int reg_index;
    };

    struct AXIObject
    {
        std::string name;
        uint64_t size;
        uint32_t reg_offset;
        uint64_t assigned_offset;
        uint64_t assigned_size;
    };

    std::vector<SignalObject> signal_list;
    std::vector<TriggerObject> trigger_list;
    std::vector<AXIObject> axi_list;

    template<typename T>
    int list_lookup(const std::string &name, const std::vector<T> &list)
    {
        for (size_t i = 0; i < list.size(); i++)
            if (list.at(i).name == name)
                return i;
        return -1;
    }

    template<typename T>
    std::string list_get_name(int index, const std::vector<T> &list)
    {
        return list.at(index).name;
    }

    void init_uma();
    void init_signal();
    void init_trigger();
    void init_axi();

    std::priority_queue<EventHolder> event_queue;
    std::map<int, std::unique_ptr<Callback>> trigger_callbacks;
    bool run_flag = false;

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

    int lookup_signal(const std::string &name) { return list_lookup(name, signal_list); }
    std::string get_signal_name(int index) { return list_get_name(index, signal_list); }

    BitVector get_signal(int index);
    void set_signal(int index, const BitVector &value);

    // Trigger

    int lookup_trigger(const std::string &name) { return list_lookup(name, trigger_list); }
    std::string get_trigger_name(int index) { return list_get_name(index, trigger_list); }

    bool is_trigger_active(int index);
    bool get_trigger_enable(int index);
    void set_trigger_enable(int index, bool enable);
    std::vector<int> get_active_triggers(bool enabled);

    // AXI

    int lookup_axi(const std::string &name) { return list_lookup(name, axi_list); }
    std::string get_axi_name(int index) { return list_get_name(index, axi_list); }

    // Scheduling

    void schedule_event(Event* event)
    {
        if (event->tick() < get_tick_count())
            throw std::runtime_error("scheduling event behind current tick");

        event_queue.push(event);
    }

    void register_trigger_callback(int index, Callback *callback)
    {
        trigger_callbacks[index] = std::unique_ptr<Callback>(callback);
    }

    void stop();

    void main_loop();

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
