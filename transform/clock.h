#ifndef _EMU_TRANSFORM_CLOCK_H_
#define _EMU_TRANSFORM_CLOCK_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"
#include "utils.h"

namespace REMU {

struct ClockTreeRewriter
{
    Hierarchy hier;
    EmulationDatabase &database;

    void run();

    static Yosys::IdString to_ff_clk(Yosys::SigBit clk) { return "\\" + Yosys::pretty_name(clk, false) + "_FF"; }
    static Yosys::IdString to_ram_clk(Yosys::SigBit clk) { return "\\" + Yosys::pretty_name(clk, false) + "_RAM"; }

    ClockTreeRewriter(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

};

#endif // #ifndef _EMU_TRANSFORM_CLOCK_H_
