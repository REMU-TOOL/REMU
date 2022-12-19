#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "yaml-cpp/yaml.h"
#include "emu_config.h"
#include "axi.h"

namespace Emu {

struct FFInfo : public FFConfig
{
    Yosys::Const init_data;
};

struct RAMInfo : public RAMConfig
{
    Yosys::Const init_data;
};

struct ClockInfo : public ClockConfig
{
    Yosys::IdString ff_clk;
    Yosys::IdString ram_clk;
};

struct ResetInfo : public ResetConfig
{
};

struct TrigInfo : public TrigConfig
{
};

struct FifoPortInfo : public FifoPortConfig
{
    Yosys::IdString port_enable;
    Yosys::IdString port_data;
    Yosys::IdString port_flag;
};

struct AXIIntfInfo : public AXIConfig
{
    AXI::AXI4 axi;
};

struct ModelInfo : public ModelConfig
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
    std::vector<std::string> deps; // relative to path
    std::vector<Yosys::IdString> payloads; // relative to path
};

struct EmulationDatabase
{
    std::vector<FFInfo> ff_list;
    std::vector<RAMInfo> ram_list;
    std::vector<ClockInfo> user_clocks;
    std::vector<ResetInfo> user_resets;
    std::vector<TrigInfo> user_trigs;
    std::vector<FifoPortInfo> fifo_ports;
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
