#ifndef _EMU_TRANSFORM_PLATFORM_H_
#define _EMU_TRANSFORM_PLATFORM_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"
#include "emulib.h"

namespace REMU {

struct PlatformTransform
{
    Yosys::Design *design;
    EmulationDatabase &database;
    EmuLibInfo &emulib;

    void run();

    PlatformTransform(Yosys::Design *design, EmulationDatabase &database, EmuLibInfo &emulib)
        : design(design), database(database), emulib(emulib) {}
};

};

#endif // #ifndef _EMU_TRANSFORM_PLATFORM_H_
