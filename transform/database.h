#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "yaml-cpp/yaml.h"
#include "hier.h"
#include "design_info.h"

namespace Emu {

struct FFInfo
{
    std::vector<Yosys::IdString> name;
    int width;
    int offset;
    Yosys::Const init_data;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["name"] = name;
        res["width"] = width;
        res["offset"] = offset;
        return res;
    }
};

struct RAMInfo
{
    std::vector<Yosys::IdString> name;
    Yosys::Const init_data;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["name"] = name;
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

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["ff_clk"] = ff_clk;
        res["ram_clk"] = ram_clk;
        return res;
    }
};

struct ResetInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    // TODO: duration, etc.

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        return res;
    }
};

struct TrigInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    std::string desc;

    YAML::Node to_yaml() const
    {
        YAML::Node res;
        res["path"] = path;
        res["orig_name"] = orig_name;
        res["port_name"] = port_name;
        res["desc"] = desc;
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
        res["port_valid"] = port_valid;
        res["port_ready"] = port_ready;
        res["deps"] = deps;
        res["payloads"] = payloads;
        return res;
    }
};

struct ModelInfo
{
    std::vector<std::string> name;
    std::string type;
};

struct EmulationDatabase
{
    DesignInfo design_info;
    std::vector<FFInfo> ff_list;
    std::vector<RAMInfo> ram_list;
    std::vector<ClockInfo> user_clocks;
    std::vector<ResetInfo> user_resets;
    std::vector<TrigInfo> user_trigs;
    std::vector<FifoPortInfo> fifo_ports;
    std::vector<ChannelInfo> channels;
    std::vector<ModelInfo> models;

    // written by IdentifySyncReadMem to tag sync read ports (mem, rd_index)
    Yosys::pool<std::pair<Yosys::Cell *, int>> mem_sr_addr;
    Yosys::pool<std::pair<Yosys::Cell *, int>> mem_sr_data;

    void write_init(std::string init_file);
    void write_yaml(std::string yaml_file);
    void write_loader(std::string loader_file);

    EmulationDatabase(Yosys::Design *design);
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

#undef EMU_CONV_DEF

}; // namespace YAML

#endif // #ifndef _DATABASE_H_
