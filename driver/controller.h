#ifndef _REMU_CONTROLLER_H_
#define _REMU_CONTROLLER_H_

#include <memory>
#include <vector>
#include <unordered_map>
#include <iostream>
#include <optional>

#include "emu_info.h"
#include "signal_info.h"
#include "checkpoint.h"
#include "uma.h"
#include "scheduler.h"

namespace REMU {

struct SignalObject
{
    int index;
    std::string name;
    int width;
    bool output;
    uint32_t reg_offset;
};

struct TriggerObject
{
    int index;
    std::string name;
    int reg_index;
};

struct AXIObject
{
    int index;
    std::string name;
    uint64_t size;
    uint32_t reg_offset;
    uint64_t assigned_offset;
    uint64_t assigned_size;
};

template<typename T>
class ObjectManager
{
    std::vector<T> obj_list;
    std::unordered_map<std::string, int> name_map;

public:

    void add(const T &obj)
    {
        std::string name = obj.name;
        int index = obj_list.size();
        obj.index = index;
        obj_list.push_back(obj);
        name_map.insert({name, index});
    }

    void add(T &&obj)
    {
        std::string name = obj.name;
        int index = obj_list.size();
        obj.index = index;
        obj_list.push_back(std::move(obj));
        name_map.insert({name, index});
    }

    int lookup(const std::string &name) const
    {
        if (name_map.find(name) == name_map.end())
            return -1;
        return name_map.at(name);
    }

    T& get(int index) { return obj_list.at(index); }
    const T& get(int index) const { return obj_list.at(index); }

    T& get(const std::string name) { return get(lookup(name)); }
    const T& get(const std::string name) const { return get(lookup(name)); }

    int size() const { return obj_list.size(); }

    typename std::vector<T>::iterator begin() { return obj_list.begin(); }
    typename std::vector<T>::iterator end() { return obj_list.end(); }
    typename std::vector<T>::const_iterator begin() const { return obj_list.begin(); }
    typename std::vector<T>::const_iterator end() const { return obj_list.end(); }
};

class Controller
{
    std::unique_ptr<UserMem> mem;
    std::unique_ptr<UserIO> reg;

    ObjectManager<SignalObject> om_signal;
    ObjectManager<TriggerObject> om_trigger;
    ObjectManager<AXIObject> om_axi;

    void init_uma(const PlatInfo &platinfo);
    void init_signal(const SysInfo &sysinfo);
    void init_trigger(const SysInfo &sysinfo);
    void init_axi(const SysInfo &sysinfo);

public:

    std::unique_ptr<UserMem> const& memory() const { return mem; }

    static void sleep();

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

    ObjectManager<SignalObject> const& signals() const { return om_signal; }
    ObjectManager<TriggerObject> const& triggers() const { return om_trigger; }
    ObjectManager<AXIObject> const& axis() const { return om_axi; }

    BitVector get_signal_value(int index);
    void set_signal_value(int index, const BitVector &value);

    bool is_trigger_active(int index);
    bool get_trigger_enable(int index);
    void set_trigger_enable(int index, bool enable);
    std::vector<int> get_active_triggers(bool enabled);

    Controller(const SysInfo &sysinfo, const PlatInfo &platinfo)
    {
        init_uma(platinfo);
        init_signal(sysinfo);
        init_trigger(sysinfo);
        init_axi(sysinfo);
    }
};

};

#endif
