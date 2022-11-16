#ifndef _EMU_PACKAGE_H_
#define _EMU_PACKAGE_H_

#include "kernel/yosys.h"

#include "hier.h"

namespace Emu {

struct PackageWorker
{
    Hierarchy hier;

    void run();

    PackageWorker(Yosys::Design *design)
        : hier(design) {}
};

};

#endif // #ifndef _EMU_PACKAGE_H_
