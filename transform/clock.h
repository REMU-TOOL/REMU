#ifndef _EMU_CLOCK_H_
#define _EMU_CLOCK_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

struct ClockTreeHelper
{
    Hierarchy hier;
    Yosys::dict<Yosys::IdString, Yosys::pool<Yosys::SigBit>> primary_clock_bits;

    void addTopClock(Yosys::SigBit clk)
    {
        log_assert(clk.is_wire());
        log_assert(clk.wire->module->name == hier.top);
        primary_clock_bits[hier.top].insert(clk);
    }

    void run();

    ClockTreeHelper(Yosys::Design *design) : hier(design) {}
};

};

#endif // #ifndef _EMU_CLOCK_H_
