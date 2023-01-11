#ifndef _EMU_TRANSFORM_MODEL_H_
#define _EMU_TRANSFORM_MODEL_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

struct ModelAnalyzer
{
    Hierarchy hier;
    EmulationDatabase &database;

    void run();

    ModelAnalyzer(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

};

#endif // #ifndef _EMU_TRANSFORM_MODEL_H_
