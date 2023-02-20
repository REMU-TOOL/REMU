#ifndef _EMU_TRANSFORM_SCANCHAIN_H_
#define _EMU_TRANSFORM_SCANCHAIN_H_

#include "kernel/yosys.h"

#include "hier.h"
#include "database.h"

namespace REMU {

struct WireInfoWithName
{
    std::vector<std::string> name;
    SysInfo::WireInfo wire;
};

struct RAMInfoWithName
{
    std::vector<std::string> name;
    SysInfo::RAMInfo ram;
};

struct ScanchainWorker
{
    Hierarchy hier;
    EmulationDatabase &database;

    Yosys::dict<Yosys::IdString, Yosys::dict<std::vector<std::string>, SysInfo::WireInfo>> all_wire_infos; // module name -> {wire name -> info}
    Yosys::dict<Yosys::IdString, Yosys::dict<std::vector<std::string>, SysInfo::RAMInfo>> all_ram_infos; // module name -> {ram name -> info}

    Yosys::dict<Yosys::IdString, std::vector<SysInfo::ScanFFInfo>> ff_lists;
    Yosys::dict<Yosys::IdString, std::vector<SysInfo::ScanRAMInfo>> ram_lists;

    static Yosys::IdString derived_name(Yosys::IdString orig_name)
    {
        return orig_name.str() + "_SCANINST";
    }

    void handle_ignored_ff(Yosys::Module *module, Yosys::FfInitVals &initvals);

    void instrument_module_ff
    (
        Yosys::Module *module,
        Yosys::SigSpec ff_di,
        Yosys::SigSpec ff_do,
        Yosys::SigSpec &ff_sigs,
        std::vector<SysInfo::ScanFFInfo> &info_list
    );

    void restore_sync_read_port_ff
    (
        Yosys::Module *module,
        Yosys::SigSpec ff_di,
        Yosys::SigSpec ff_do,
        Yosys::SigSpec &ff_sigs,
        std::vector<SysInfo::ScanFFInfo> &info_list
    );

    void instrument_module_ram
    (
        Yosys::Module *module,
        Yosys::SigSpec ram_di,
        Yosys::SigSpec ram_do,
        Yosys::SigSpec ram_li,
        Yosys::SigSpec ram_lo,
        Yosys::dict<std::vector<std::string>, SysInfo::RAMInfo> &ram_infos,
        std::vector<SysInfo::ScanRAMInfo> &info_list
    );

    void parse_dissolved_rams
    (
        Yosys::Module *module,
        Yosys::dict<std::vector<std::string>, SysInfo::RAMInfo> &ram_infos
    );

    void instrument_module(Yosys::Module *module);
    void tieoff_ram_last(Yosys::Module *module);
    void run();

    ScanchainWorker(Yosys::Design *design, EmulationDatabase &database)
        : hier(design), database(database) {}
};

};

#endif // #ifndef _EMU_TRANSFORM_SCANCHAIN_H_
