#ifndef _REMU_HAL_H_
#define _REMU_HAL_H_

// Hardware Abstraction Layer

#include <vector>
#include <memory>

#include "uma.h"

namespace REMU {

class HAL
{
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
        _MAX,
    };

    static const char * const mode_str[_MAX];

    Mode get_mode();
    void set_mode(Mode mode);

    uint64_t get_tick_count();
    void set_tick_count(uint64_t count);
    void set_step_count(uint32_t count);

    bool is_trigger_active(int id);
    bool get_trigger_enable(int id);
    void set_trigger_enable(int id, bool enable);
    std::vector<int> get_active_triggers(bool enabled);

    void get_signal_value(int reg_offset, int nblks, uint32_t *data);
    void set_signal_value(int reg_offset, int nblks, uint32_t *data);

    static void sleep(unsigned int milliseconds);

    HAL(std::unique_ptr<UserMem> &&mem, std::unique_ptr<UserIO> &&reg) : mem(std::move(mem)), reg(std::move(reg)) {}
};

};

#endif
