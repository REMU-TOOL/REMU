#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "designtools.h"

namespace Emu {

USING_YOSYS_NAMESPACE

struct FfInfoChunk {
    std::string wire_name;
    int wire_width;
    int wire_start_offset;
    bool wire_upto;
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
    std::string name;
    int depth;
    int slices;
    int mem_width;
    int mem_depth;
    int mem_start_offset;
    bool is_src;
    bool is_model;
    Const init_data;
};

class FfMemInfoExtractor {

    DesignInfo &design;
    Module *target;

public:

    FfInfo ff(const SigSpec &sig, const Const &initval);
    MemInfo mem(const Mem &mem, int slices);

    FfMemInfoExtractor(DesignInfo &design, Module *target)
        : design(design), target(target) {}

};

struct ClockInfo {
    // TODO: frequency, phase, etc.
    std::string ff_clk;
    std::string ram_clk;
};

struct EmulationDatabase {

    // written by PlatformTransform
    int scctrl_base = 0;

    // written by PortTransform
    dict<std::string, ClockInfo> dutclocks;

    // written by InsertScanchain
    int ff_width = 0;
    int ram_width = 0;
    std::vector<FfInfo> scanchain_ff;
    std::vector<MemInfo> scanchain_ram;

    // written by IdentifySyncReadMem to tag sync read ports (mem, rd_index)
    pool<std::pair<Cell *, int>> mem_sr_addr;
    pool<std::pair<Cell *, int>> mem_sr_data;

    void write_init(std::string init_file);
    void write_yaml(std::string yaml_file);
    void write_loader(std::string loader_file);

};

} // namespace Emu

#endif // #ifndef _DATABASE_H_
