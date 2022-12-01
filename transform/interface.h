#ifndef _EMU_INTERFACE_H_
#define _EMU_INTERFACE_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "axi.h"
#include "database.h"

namespace Emu {

struct AXIHelper {
    static AXI::AXI4Lite axi4lite_from_prefix(Yosys::Module *module, const std::string &prefix);
    static AXI::AXI4 axi4_from_prefix(Yosys::Module *module, const std::string &prefix);
};

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

#endif // #ifndef _EMU_INTERFACE_H_
