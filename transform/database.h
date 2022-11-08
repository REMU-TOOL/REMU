#ifndef _DATABASE_H_
#define _DATABASE_H_

#include "kernel/yosys.h"
#include "yaml-cpp/yaml.h"
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

#define DB_ENCODE(node, field) node[#field] = field
#define DB_ENCODE_ENUM(node, field) node[#field] = static_cast<int>(field)
#define DB_DECODE(node, field) field = node[#field].as<decltype(field)>()
#define DB_DECODE_ENUM(node, field) field = static_cast<decltype(field)>(node[#field].as<int>())

struct ClockInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    // TODO: frequency, phase, etc.
    Yosys::IdString ff_clk;
    Yosys::IdString ram_clk;

    YAML::Node encode() const
    {
        YAML::Node res;
        DB_ENCODE(res, path);
        DB_ENCODE(res, orig_name);
        DB_ENCODE(res, port_name);
        DB_ENCODE(res, ff_clk);
        DB_ENCODE(res, ram_clk);
        return res;
    }

    ClockInfo() = default;

    ClockInfo(const YAML::Node &node)
    {
        DB_DECODE(node, path);
        DB_DECODE(node, orig_name);
        DB_DECODE(node, port_name);
        DB_DECODE(node, ff_clk);
        DB_DECODE(node, ram_clk);
    }
};

struct ResetInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    // TODO: duration, etc.

    YAML::Node encode() const
    {
        YAML::Node res;
        DB_ENCODE(res, path);
        DB_ENCODE(res, orig_name);
        DB_ENCODE(res, port_name);
        return res;
    }

    ResetInfo() = default;

    ResetInfo(const YAML::Node &node)
    {
        DB_DECODE(node, path);
        DB_DECODE(node, orig_name);
        DB_DECODE(node, port_name);
    }
};

struct TrigInfo
{
    std::vector<Yosys::IdString> path;
    Yosys::IdString orig_name;
    Yosys::IdString port_name;
    std::string desc;

    YAML::Node encode() const
    {
        YAML::Node res;
        DB_ENCODE(res, path);
        DB_ENCODE(res, orig_name);
        DB_ENCODE(res, port_name);
        DB_ENCODE(res, desc);
        return res;
    }

    TrigInfo() = default;

    TrigInfo(const YAML::Node &node)
    {
        DB_DECODE(node, path);
        DB_DECODE(node, orig_name);
        DB_DECODE(node, port_name);
        DB_DECODE(node, desc);
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

    YAML::Node encode() const
    {
        YAML::Node res;
        DB_ENCODE(res, path);
        DB_ENCODE(res, orig_name);
        DB_ENCODE(res, port_name);
        DB_ENCODE_ENUM(res, type);
        DB_ENCODE(res, width);
        DB_ENCODE(res, port_enable);
        DB_ENCODE(res, port_data);
        DB_ENCODE(res, port_flag);
        return res;
    }

    FifoPortInfo() = default;

    FifoPortInfo(const YAML::Node &node)
    {
        DB_DECODE(node, path);
        DB_DECODE(node, orig_name);
        DB_DECODE(node, port_name);
        DB_DECODE_ENUM(node, type);
        DB_DECODE(node, width);
        DB_DECODE(node, port_enable);
        DB_DECODE(node, port_data);
        DB_DECODE(node, port_flag);
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

    YAML::Node encode() const
    {
        YAML::Node res;
        DB_ENCODE(res, path);
        DB_ENCODE(res, orig_name);
        DB_ENCODE(res, port_name);
        DB_ENCODE_ENUM(res, dir);
        DB_ENCODE(res, port_valid);
        DB_ENCODE(res, port_ready);
        DB_ENCODE(res, deps);
        DB_ENCODE(res, payloads);
        return res;
    }

    ChannelInfo() = default;

    ChannelInfo(const YAML::Node &node)
    {
        DB_DECODE(node, path);
        DB_DECODE(node, orig_name);
        DB_DECODE(node, port_name);
        DB_DECODE_ENUM(node, dir);
        DB_DECODE(node, port_valid);
        DB_DECODE(node, port_ready);
        DB_DECODE(node, deps);
        DB_DECODE(node, payloads);
    }
};

#undef DB_ENCODE
#undef DB_ENCDE_ENUM
#undef DB_DECODE
#undef DB_DECODE_ENUM

template<typename T>
struct YAMLConv
{
    static YAML::Node encode(const T &rhs)
    {
        return rhs.encode();
    }

    static bool decode(const YAML::Node& node, T& rhs)
    {
        return T(node);
    }
};

struct ModelInfo
{
    std::vector<std::string> name;
    std::string type;
};

struct EmulationDatabase
{
    std::vector<ClockInfo> user_clocks;
    std::vector<ResetInfo> user_resets;
    std::vector<TrigInfo> user_trigs;
    std::vector<FifoPortInfo> fifo_ports;
    std::vector<ChannelInfo> channels;
    std::vector<ModelInfo> models;

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

template<> struct convert<Emu::ClockInfo> : public Emu::YAMLConv<Emu::ClockInfo> {};
template<> struct convert<Emu::ResetInfo> : public Emu::YAMLConv<Emu::ResetInfo> {};
template<> struct convert<Emu::TrigInfo> : public Emu::YAMLConv<Emu::TrigInfo> {};
template<> struct convert<Emu::FifoPortInfo> : public Emu::YAMLConv<Emu::FifoPortInfo> {};
template<> struct convert<Emu::ChannelInfo> : public Emu::YAMLConv<Emu::ChannelInfo> {};

}; // namespace YAML

#endif // #ifndef _DATABASE_H_
