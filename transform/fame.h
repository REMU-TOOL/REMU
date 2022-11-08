#ifndef _EMU_FAME_H_
#define _EMU_FAME_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

struct FAMETransformer
{
    Yosys::Design *design;
    Hierarchy hier;
    EmulationDatabase &database;


};

};

#endif // #ifndef _EMU_FAME_H_
