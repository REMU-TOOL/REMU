#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "yaml-cpp/yaml.h"
#include "emu_config.h"
#include "axi.h"

namespace Emu {

struct FFInfo : public Config::FF
{
    Yosys::Const init_data;
};

struct RAMInfo : public Config::RAM
{
    Yosys::Const init_data;
};

struct ClockInfo : public Config::Clock
{
    Yosys::IdString ff_clk;
    Yosys::IdString ram_clk;
};

struct ResetInfo : public Config::Reset
{
};

struct TrigInfo : public Config::Trig
{
};

struct PipeInfo : public Config::Pipe
{
    Yosys::IdString port_valid;
    Yosys::IdString port_ready;
    Yosys::IdString port_data;
    Yosys::IdString port_empty; // only for input direction
};

struct AXIIntfInfo : public Config::AXI
{
    AXI::AXI4 axi;
};

struct ModelInfo : public Config::Model
{
};

struct ChannelInfo
{
    std::vector<std::string> path;
    std::string orig_name;
    std::string port_name;
    enum {IN, OUT} dir;
    Yosys::IdString port_valid;
    Yosys::IdString port_ready;
    Yosys::IdString port_payload_inner;
    Yosys::IdString port_payload_outer;
    std::vector<std::string> deps; // relative to path
};

struct EmulationDatabase
{
    std::vector<FFInfo> ff_list;
    std::vector<RAMInfo> ram_list;
    std::vector<ClockInfo> user_clocks;
    std::vector<ResetInfo> user_resets;
    std::vector<TrigInfo> user_trigs;
    std::vector<PipeInfo> pipes;
    std::vector<AXIIntfInfo> axi_intfs;
    std::vector<ModelInfo> models;
    std::vector<ChannelInfo> channels;

    void write_init(std::string init_file);
    void write_yaml(std::string yaml_file);
    void write_loader(std::string loader_file);

    EmulationDatabase() {}
};

} // namespace Emu

#endif // #ifndef _DATABASE_H_
