#ifndef _EMU_CLOCK_H_
#define _EMU_CLOCK_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

struct ClockTreeRewriter
{
    Hierarchy hier;
    EmulationDatabase &database;

    void run();

    ClockTreeRewriter(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

};

#endif // #ifndef _EMU_CLOCK_H_
