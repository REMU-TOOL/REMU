#ifndef _EMU_TRANSFORM_CLOCK_H_
#define _EMU_TRANSFORM_CLOCK_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace REMU {

struct ClockTreeRewriter
{
    Hierarchy hier;
    EmulationDatabase &database;

    void run();

    ClockTreeRewriter(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

};

#endif // #ifndef _EMU_TRANSFORM_CLOCK_H_
