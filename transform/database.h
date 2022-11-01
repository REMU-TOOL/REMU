#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"

#include "circuit_info.h"

namespace Emu {

struct FfInfoChunk {
    std::vector<std::string> wire_name;
    int wire_width;         // redundant, kept for write_* use
    int wire_start_offset;  // redundant, kept for write_* use
    bool wire_upto;         // redundant, kept for write_* use
    int width;
    int offset;
    bool is_src;
};

struct FfInfo {
    std::vector<FfInfoChunk> info;
    Yosys::Const initval;
};

struct MemInfo {
    std::vector<std::string> name;
    int depth;
    int slices;
    int mem_width;          // redundant, kept for write_* use
    int mem_depth;          // redundant, kept for write_* use
    int mem_start_offset;   // redundant, kept for write_* use
    bool is_src;
    Yosys::Const init_data;
};

struct InfoWithScope {
    std::vector<Yosys::IdString> scope; // reversed path
};

template<typename T>
struct InfoWithName {
    T orig_name;
    T port_name;
};

struct SinglePortBaseInfo : public InfoWithScope, public InfoWithName<Yosys::IdString> {};
struct GroupPortBaseInfo : public InfoWithScope, public InfoWithName<std::string> {};

struct PortInfo : public SinglePortBaseInfo {
    std::vector<Yosys::IdString> scope; // reversed path
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
};

struct ClockInfo : public SinglePortBaseInfo {
    // TODO: frequency, phase, etc.
    Yosys::IdString ff_clk;
    Yosys::IdString ram_clk;
};

struct ResetInfo : public SinglePortBaseInfo {
    // TODO: duration, etc.
};

struct TrigInfo : public SinglePortBaseInfo {
    std::string desc;
};

struct FifoPortInfo : public GroupPortBaseInfo {
    std::vector<Yosys::IdString> scope; // reversed path
    std::string name;
    enum {SOURCE, SINK} type;
    int width = 0;
};

struct ChannelInfo : public GroupPortBaseInfo {
    std::vector<Yosys::IdString> scope; // reversed path
    std::string name;
    enum {IN, OUT} dir;
    std::vector<std::string> deps;
    Yosys::IdString valid;
    Yosys::IdString ready;
    std::vector<Yosys::IdString> payloads;
};

struct ModelInfo {
    std::vector<std::string> name;
    std::string type;
};

struct EmulationDatabase
{
    Yosys::IdString top;

    Yosys::dict<Yosys::IdString, std::vector<ClockInfo>> user_clocks;
    Yosys::dict<Yosys::IdString, std::vector<ResetInfo>> user_resets;
    Yosys::dict<Yosys::IdString, std::vector<TrigInfo>> user_trigs;
    Yosys::dict<Yosys::IdString, std::vector<FifoPortInfo>> fifo_ports;
    Yosys::dict<Yosys::IdString, std::vector<ChannelInfo>> channels;
    Yosys::dict<Yosys::IdString, std::vector<ModelInfo>> models;

    // written by InsertScanchain
    int ff_width;
    int ram_width;
    CircuitInfo::Builder ci_root;
    std::vector<FfInfo> scanchain_ff;
    std::vector<MemInfo> scanchain_ram;

    // written by IdentifySyncReadMem to tag sync read ports (mem, rd_index)
    Yosys::pool<std::pair<Yosys::Cell *, int>> mem_sr_addr;
    Yosys::pool<std::pair<Yosys::Cell *, int>> mem_sr_data;

    void write_init(std::string init_file);
    void write_yaml(std::string yaml_file);
    void write_loader(std::string loader_file);

    EmulationDatabase() : ff_width(0), ram_width(0) {}
};

#if 0
class FfMemInfoExtractor {

    DesignHierarchy &design;
    Module *target;
    EmulationDatabase &database;

public:

    void add_ff(const SigSpec &sig, const Const &initval);
    void add_mem(const Mem &mem, int slices);

    FfMemInfoExtractor(DesignHierarchy &design, Module *target, EmulationDatabase &database)
        : design(design), target(target), database(database)
    {
        database.ci_root.name = design.name_of(target);
    }

};
#endif

} // namespace Emu

#endif // #ifndef _DATABASE_H_
