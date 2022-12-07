#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "yaml-cpp/yaml.h"
#include "hier.h"
#include "axi.h"

namespace Emu {

struct FFInfo
{
    std::vector<Yosys::IdString> name;
    int width;
    int offset;
    int wire_width;         // redundant for write_loader use
    int wire_start_offset;  // redundant for write_loader use
    bool wire_upto;         // redundant for write_loader use
    Yosys::Const init_data;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["name"] = name;
        res["width"] = width;
        res["offset"] = offset;
        res["wire_width"] = wire_width;
        res["wire_start_offset"] = wire_start_offset;
        res["wire_upto"] = wire_upto;
        return res;
    }
};

struct RAMInfo
{
    std::vector<Yosys::IdString> name;
    int width;          // redundant for write_loader use
    int depth;          // redundant for write_loader use
    int start_offset;   // redundant for write_loader use
    bool dissolved;
    Yosys::Const init_data;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["name"] = name;
        res["width"] = width;
        res["depth"] = depth;
        res["start_offset"] = start_offset;
        res["dissolved"] = dissolved;
        return res;
    }
};

struct ClockInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    // TODO: frequency, phase, etc.
    Yosys::IdString ff_clk;
    Yosys::IdString ram_clk;
    int index = -1;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["ff_clk"] = ff_clk;
        res["ram_clk"] = ram_clk;
        res["index"] = index;
        return res;
    }
};

struct ResetInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    // TODO: duration, etc.
    int index = -1;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["index"] = index;
        return res;
    }
};

struct TrigInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    std::string desc;
    int index = -1;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["desc"] = desc;
        res["index"] = index;
        return res;
    }
};

struct FifoPortInfo
{
    std::vector<Yosys::IdString> path;
    std::string orig_name;
    std::string port_name;
    enum {SOURCE, SINK} type;
    int width = 0;
    Yosys::IdString port_enable;
    Yosys::IdString port_data;
    Yosys::IdString port_flag;
    int index = -1;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["type"] = static_cast<int>(type);
        res["width"] = width;
        res["port_enable"] = port_enable;
        res["port_data"] = port_data;
        res["port_flag"] = port_flag;
        res["index"] = index;
        return res;
    }
};

struct ChannelInfo
{
    std::vector<Yosys::IdString> path;
    std::string orig_name;
    std::string port_name;
    enum {IN, OUT} dir;
    Yosys::IdString port_valid;
    Yosys::IdString port_ready;
    std::vector<std::string> deps; // relative to path
    std::vector<Yosys::IdString> payloads; // relative to path

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["dir"] = static_cast<int>(dir);
        res["deps"] = deps;
        return res;
    }
};

struct AXIIntfInfo
{
    std::vector<Yosys::IdString> path;
    std::string orig_name;
    std::string port_name;
    std::string addr_space;
    int addr_pages;
    AXI::AXI4 axi;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["addr_space"] = addr_space;
        res["addr_pages"] = addr_pages;
        return res;
    }
};

struct ModelInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString name;
    std::string type;
};

struct EmulationDatabase
{
    std::vector<FFInfo> ff_list;
    std::vector<RAMInfo> ram_list;
    std::vector<ClockInfo> user_clocks;
    std::vector<ResetInfo> user_resets;
    std::vector<TrigInfo> user_trigs;
    std::vector<FifoPortInfo> fifo_ports;
    std::vector<ChannelInfo> channels;
    std::vector<AXIIntfInfo> axi_intfs;
    std::vector<ModelInfo> models;

    void write_init(std::string init_file);
    void write_yaml(std::string yaml_file);
    void write_loader(std::string loader_file);

    EmulationDatabase() {}
};

} // namespace Emu

namespace YAML {

template<>
struct convert<Yosys::IdString>
{
    static Node encode(Yosys::IdString rhs)
    {
        return Node(rhs[0] == '\\' ? rhs.substr(1) : rhs.str());
    }

    static bool decode(const Node& node, Yosys::IdString& rhs)
    {
        std::string temp;
        if (!convert<std::string>::decode(node, temp))
            return false;
        rhs = '\\' + temp;
        return true;
    }
};

#define EMU_CONV_DEF(type) \
    template<> \
    struct convert<type> \
    { \
        static Node encode(const type &rhs) \
        { \
            return rhs.to_yaml(); \
        } \
    };

EMU_CONV_DEF(Emu::FFInfo)
EMU_CONV_DEF(Emu::RAMInfo)
EMU_CONV_DEF(Emu::ClockInfo)
EMU_CONV_DEF(Emu::ResetInfo)
EMU_CONV_DEF(Emu::TrigInfo)
EMU_CONV_DEF(Emu::FifoPortInfo)
EMU_CONV_DEF(Emu::ChannelInfo)
EMU_CONV_DEF(Emu::AXIIntfInfo)

#undef EMU_CONV_DEF

}; // namespace YAML

#endif // #ifndef _DATABASE_H_
