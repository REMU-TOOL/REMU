#ifndef _INTERFACE_H_
#define _INTERFACE_H_

#include "kernel/yosys.h"
#include "designtools.h"
#include "database.h"

namespace Emu {

USING_YOSYS_NAMESPACE

struct ExportInterfaceWorker {

    EmulationDatabase &database;
    DesignInfo designinfo;
    HierconnBuilder hierconn;

    void process_module(Module *module);
    void run();

    ExportInterfaceWorker(EmulationDatabase &database, Design *design)
        : database(database), designinfo(design), hierconn(designinfo) {}

};

} // namespace Emu

#endif // #ifndef _INTERFACE_H_
