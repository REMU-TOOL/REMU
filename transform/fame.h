#ifndef _EMU_TRANSFORM_FAME_H_
#define _EMU_TRANSFORM_FAME_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace REMU {

struct FAMETransform
{
    Yosys::Design *design;
    EmulationDatabase &database;

    void run();

    FAMETransform(Yosys::Design *design, EmulationDatabase &database)
        : design(design), database(database) {}
};

};

#endif // #ifndef _EMU_TRANSFORM_FAME_H_
