#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "designtools.h"

#include "circuit_info.h"

namespace Emu {

USING_YOSYS_NAMESPACE

struct FfInfoChunk {
    std::vector<std::string> wire_name;
    int wire_width;         // redundant, kept for write_* use
    int wire_start_offset;  // redundant, kept for write_* use
    bool wire_upto;         // redundant, kept for write_* use
    int width;
    int offset;
    bool is_src;
    bool is_model;
};

struct FfInfo {
    std::vector<FfInfoChunk> info;
    Const initval;
};

struct MemInfo {
    std::vector<std::string> name;
    int depth;
    int slices;
    int mem_width;          // redundant, kept for write_* use
    int mem_depth;          // redundant, kept for write_* use
    int mem_start_offset;   // redundant, kept for write_* use
    bool is_src;
    bool is_model;
    Const init_data;
};

struct ClockInfo {
    // TODO: frequency, phase, etc.
    std::string name;
    std::string ff_clk;
    std::string ram_clk;
};

struct ResetInfo {
    // TODO: duration, etc.
    std::string name;
    int index = -1;
};

struct TrigInfo {
    std::string name;
    std::string desc;
    int index = -1;
};

struct FifoPortInfo {
    std::string name;
    std::string type;
    std::string port_enable;
    std::string port_data;
    std::string port_flag;
    int width = 0;
    int index = -1;
};

struct EmulationDatabase {

    // written by PortTransform, ClockTransform, PlatformTransform
    std::vector<ClockInfo> user_clocks;
    std::vector<ResetInfo> user_resets;
    std::vector<TrigInfo> user_trigs;
    std::vector<FifoPortInfo> fifo_ports;

    // written by InsertScanchain
    int ff_width;
    int ram_width;
    CircuitInfo::Root ci_root;
    std::vector<FfInfo> scanchain_ff;
    std::vector<MemInfo> scanchain_ram;

    // written by IdentifySyncReadMem to tag sync read ports (mem, rd_index)
    pool<std::pair<Cell *, int>> mem_sr_addr;
    pool<std::pair<Cell *, int>> mem_sr_data;

    void write_init(std::string init_file);
    void write_yaml(std::string yaml_file);
    void write_loader(std::string loader_file);

    EmulationDatabase() : ff_width(0), ram_width(0) {}

};

class FfMemInfoExtractor {

    DesignInfo &design;
    Module *target;
    EmulationDatabase &database;

public:

    void add_ff(const SigSpec &sig, const Const &initval);
    void add_mem(const Mem &mem, int slices);

    FfMemInfoExtractor(DesignInfo &design, Module *target, EmulationDatabase &database)
        : design(design), target(target), database(database)
    {
        database.ci_root.name = design.name_of(target);
    }

};

} // namespace Emu

#endif // #ifndef _DATABASE_H_
