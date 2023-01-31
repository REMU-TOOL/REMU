#ifndef _EMU_TRANSFORM_INTERFACE_H_
#define _EMU_TRANSFORM_INTERFACE_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "axi.h"
#include "database.h"

namespace REMU {

struct InterfaceWorker
{
    Hierarchy hier;
    EmulationDatabase &database;

    Yosys::dict<Yosys::IdString, std::vector<AXIIntfInfo>> all_axi_intfs;

    void promote_axi_intfs(Yosys::Module *module);
    void run();

    InterfaceWorker(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

};

#endif // #ifndef _EMU_TRANSFORM_INTERFACE_H_
