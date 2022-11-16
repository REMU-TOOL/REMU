#ifndef _EMU_SCANCHAIN_H_
#define _EMU_SCANCHAIN_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace Emu {

struct ScanchainWorker
{
    Hierarchy hier;
    EmulationDatabase &database;
    Yosys::dict<Yosys::IdString, std::vector<FFInfo>> ff_lists;
    Yosys::dict<Yosys::IdString, std::vector<RAMInfo>> ram_lists;

    static Yosys::IdString derived_name(Yosys::IdString orig_name)
    {
        return orig_name.str() + "_SCANINST";
    }

    void instrument_module_ff(Yosys::Module *module, Yosys::SigSpec ff_di, Yosys::SigSpec ff_do, std::vector<FFInfo> &info_list);
    void restore_sync_read_port_ff(Yosys::Module *module, Yosys::SigSpec ff_di, Yosys::SigSpec ff_do, std::vector<FFInfo> &info_list);
    void instrument_module_ram(Yosys::Module *module, Yosys::SigSpec ram_di, Yosys::SigSpec ram_do, Yosys::SigSpec ram_li, Yosys::SigSpec ram_lo, std::vector<RAMInfo> &info_list);
    void instrument_module(Yosys::Module *module);
    void tieoff_ram_last(Yosys::Module *module);
    void run();

    ScanchainWorker(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

};

#endif // #ifndef _EMU_SCANCHAIN_H_
