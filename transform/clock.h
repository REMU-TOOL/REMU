#ifndef _EMU_CLOCK_H_
#define _EMU_CLOCK_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "walker_cache.h"

namespace Emu {

struct ClockTreeAnalyzer
{
    Yosys::Design *design;
    Hierarchy &hier;
    Yosys::ModWalkerCache modwalkers;

    Yosys::dict<Yosys::Module*, Yosys::pool<Yosys::SigBit>> clock_signals; // sigmapped
    Yosys::dict<Yosys::Module*, Yosys::pool<Yosys::SigBit>> clock_ports; // exactly the port sigbit, not sigmapped

    void analyze_clocked_cells();
    void analyze_clock_propagation();

    void analyze()
    {
        modwalkers.clear();
        analyze_clocked_cells();
        analyze_clock_propagation();
    }

    ClockTreeAnalyzer(Yosys::Design *design, Hierarchy &hier) : design(design), hier(hier) {}
};

};

#endif // #ifndef _EMU_CLOCK_H_
