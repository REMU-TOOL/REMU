#ifndef _REMU_DRIVER_H_
#define _REMU_DRIVER_H_

#include <vector>
#include <map>
#include <memory>

#include "emu_info.h"
#include "bitvector.h"
#include "uma.h"

namespace REMU {

class Driver
{
    struct SignalObject
    {
        std::vector<std::string> name;
        int width;
        bool output;
        uint32_t reg_offset;
    };

    struct TriggerObject
    {
        std::vector<std::string> name;
        int index;
    };

    struct AXIObject
    {
        std::vector<std::string> name;
        uint64_t size;
        uint32_t reg_offset;
        uint64_t assigned_base;
        uint64_t assigned_size;
    };

    std::vector<SignalObject> signal_list;
    std::vector<TriggerObject> trigger_list;
    std::vector<AXIObject> axi_list;

    template<typename T>
    int list_lookup(const std::vector<std::string> &name, const std::vector<T> &list)
    {
        for (size_t i = 0; i < list.size(); i++)
            if (list.at(i).name == name)
                return i;
        return -1;
    }

    template<typename T>
    std::vector<std::string> list_get_name(int handle, const std::vector<T> &list)
    {
        return list.at(handle).name;
    }

    void init_signal(const SysInfo &sysinfo);
    void init_trigger(const SysInfo &sysinfo);
    void init_axi(const SysInfo &sysinfo);
    void init_system(const SysInfo &sysinfo);

    std::unique_ptr<UserMem> mem;
    std::unique_ptr<UserIO> reg;

    void enter_run_mode();
    void exit_run_mode();
    void enter_scan_mode();
    void exit_scan_mode();

public:

    enum Mode
    {
        PAUSE,
        RUN,
        SCAN,
    };

    Mode get_mode();
    void set_mode(Mode mode);

    uint64_t get_tick_count();
    void set_tick_count(uint64_t count);
    void set_step_count(uint32_t count);

    // Signal

    int lookup_signal(const std::vector<std::string> &name) { return list_lookup(name, signal_list); }
    std::vector<std::string> get_signal_name(int handle) { return list_get_name(handle, signal_list); }

    BitVector get_signal(int handle);
    void set_signal(int handle, const BitVector &value);

    // Trigger

    int lookup_trigger(const std::vector<std::string> &name) { return list_lookup(name, trigger_list); }
    std::vector<std::string> get_trigger_name(int handle) { return list_get_name(handle, trigger_list); }

    bool is_trigger_active(int handle);
    bool get_trigger_enable(int handle);
    void set_trigger_enable(int handle, bool enable);
    std::vector<int> get_active_triggers(bool enabled);

    // AXI

    int lookup_axi(const std::vector<std::string> &name) { return list_lookup(name, axi_list); }
    std::vector<std::string> get_axi_name(int handle) { return list_get_name(handle, axi_list); }

    void do_scan(uint32_t dma_addr, bool scan_in);

    static void sleep(unsigned int milliseconds);

    Driver(const SysInfo &sysinfo, std::unique_ptr<UserMem> &&mem, std::unique_ptr<UserIO> &&reg) :
        mem(std::move(mem)), reg(std::move(reg))
    {
        init_system(sysinfo);
    }
};

};

#endif
