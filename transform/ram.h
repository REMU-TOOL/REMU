#ifndef _EMU_RAM_H_
#define _EMU_RAM_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

struct RAMTransform
{
    Yosys::Design *design;
    EmulationDatabase &database;

    void run();

    RAMTransform(Yosys::Design *design, EmulationDatabase &database)
        : design(design), database(database) {}
};

};

#endif // #ifndef _EMU_RAM_H_
