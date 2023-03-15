#ifndef _REMU_CONTROLLER_H_
#define _REMU_CONTROLLER_H_

#include <memory>
#include <vector>
#include <unordered_map>
#include <iostream>
#include <optional>

#include "yaml-cpp/yaml.h"

#include "runtime_data.h"
#include "checkpoint.h"
#include "uma.h"

namespace REMU {

class Controller
{
    std::unique_ptr<UserMem> mem;
    std::unique_ptr<UserIO> reg;

    void init_uma(const YAML::Node &platinfo);

public:

    std::unique_ptr<UserMem> const& memory() const { return mem; }

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

    BitVector get_signal_value(const RTSignal &signal);
    void set_signal_value(const RTSignal &signal, const BitVector &value);

    bool is_trigger_active(const RTTrigger &trigger);
    bool get_trigger_enable(const RTTrigger &trigger);
    void set_trigger_enable(const RTTrigger &trigger, bool enable);

    void configure_axi_range(const RTAXI &axi);

    Controller(const SysInfo &sysinfo, const YAML::Node &platinfo)
    {
        init_uma(platinfo);
    }
};

};

#endif
