#ifndef _EMU_DESIGN_INFO_H_
#define _EMU_DESIGN_INFO_H_

#include "yaml-cpp/yaml.h"

namespace Emu {

struct RegInfo
{
    int width;
    int start_offset;
    bool upto;

    YAML::Node encode() const
    {
        YAML::Node res;
        res["width"] = width;
        res["start_offset"] = start_offset;
        res["upto"] = upto;
        return res;
    }

    static bool decode(const YAML::Node &node, RegInfo &res)
    {
        res.width = node["width"].as<int>();
        res.start_offset = node["start_offset"].as<int>();
        res.upto = node["upto"].as<bool>();
        return true;
    }
};

struct RegArrayInfo
{
    int width;
    int depth;
    int start_offset;
    bool dissolved;

    YAML::Node encode() const
    {
        YAML::Node res;
        res["width"] = width;
        res["depth"] = depth;
        res["start_offset"] = start_offset;
        res["dissolved"] = dissolved;
        return res;
    }

    static bool decode(const YAML::Node &node, RegArrayInfo &res)
    {
        res.width = node["width"].as<int>();
        res.depth = node["depth"].as<int>();
        res.start_offset = node["start_offset"].as<int>();
        res.dissolved = node["dissolved"].as<bool>();
        return true;
    }
};

struct CellInfo
{
    enum {
        TYPE_NONE,
        TYPE_REG,
        TYPE_REG_ARRAY,
        TYPE_MODULE,
    } type;

    union {
        RegInfo reg;
        RegArrayInfo array;
        std::string module;
    };

    void __copy_construct(const CellInfo &other)
    {
        type = other.type;
        switch (type) {
            case TYPE_REG:
                new (&reg) RegInfo(other.reg);
                break;
            case TYPE_REG_ARRAY:
                new (&array) RegArrayInfo(other.array);
                break;
            case TYPE_MODULE:
                new (&module) std::string(other.module);
                break;
            default:
                break;
        }
    }

    void __move_construct(CellInfo &&other)
    {
        type = other.type;
        switch (type) {
            case TYPE_REG:
                new (&reg) RegInfo(std::move(other.reg));
                break;
            case TYPE_REG_ARRAY:
                new (&array) RegArrayInfo(std::move(other.array));
                break;
            case TYPE_MODULE:
                new (&module) std::string(std::move(other.module));
                break;
            default:
                break;
        }
    }

    void __destroy()
    {
        switch (type) {
            case TYPE_REG:
                reg.~RegInfo();
                break;
            case TYPE_REG_ARRAY:
                array.~RegArrayInfo();
                break;
            case TYPE_MODULE:
                module.~basic_string();
                break;
            default:
                break;
        }
    }

    CellInfo() : type(TYPE_NONE) {}
    CellInfo(const RegInfo &reg) : type(TYPE_REG), reg(reg) {}
    CellInfo(RegInfo &&reg) : type(TYPE_REG), reg(std::move(reg)) {}
    CellInfo(const RegArrayInfo &array) : type(TYPE_REG_ARRAY), array(array) {}
    CellInfo(RegArrayInfo &&array) : type(TYPE_REG_ARRAY), array(std::move(array)) {}
    CellInfo(const std::string &module) : type(TYPE_MODULE), module(module) {}
    CellInfo(std::string &&module) : type(TYPE_MODULE), module(std::move(module)) {}

    CellInfo(const CellInfo &other) { __copy_construct(other); }
    CellInfo(CellInfo &&other) { __move_construct(std::move(other)); }

    ~CellInfo() { __destroy(); }

    CellInfo& operator=(const CellInfo &other)
    {
        __destroy();
        __copy_construct(other);
        return *this;
    }

    CellInfo& operator=(CellInfo &&other)
    {
        __destroy();
        __move_construct(std::move(other));
        return *this;
    }

    YAML::Node encode() const
    {
        YAML::Node res;
        switch (type) {
            case TYPE_REG:
                res["type"] = "reg";
                res["reg"] = reg;
                break;
            case TYPE_REG_ARRAY:
                res["type"] = "reg_array";
                res["reg_array"] = array;
                break;
            case TYPE_MODULE:
                res["type"] = "module";
                res["module"] = module;
                break;
            default:
                break;
        }
        return res;
    }

    static bool decode(const YAML::Node &node, CellInfo &res)
    {
        auto type = node["type"].as<std::string>();
        if (type == "reg") {
            res.type = TYPE_REG;
            res.reg = node["reg"].as<RegInfo>();
        }
        else if (type == "reg_array") {
            res.type = TYPE_REG_ARRAY;
            res.array = node["reg_array"].as<RegArrayInfo>();
        }
        else if (type == "module") {
            res.type = TYPE_MODULE;
            res.module = node["module"].as<std::string>();
        }
        else {
            return false;
        }
        return true;
    }
};

struct ModuleInfo
{
    std::map<std::string, CellInfo> cells;

    YAML::Node encode() const
    {
        YAML::Node res;
        res["cells"] = cells;
        return res;
    }

    static bool decode(const YAML::Node &node, ModuleInfo &res)
    {
        res.cells = node["cells"].as<decltype(res.cells)>();
        return true;
    }
};

struct DesignInfo
{
    std::string top;
    std::map<std::string, ModuleInfo> modules;

    YAML::Node encode() const
    {
        YAML::Node res;
        res["top"] = top;
        res["modules"] = modules;
        return res;
    }

    static bool decode(const YAML::Node &node, DesignInfo &res)
    {
        res.top = node["top"].as<std::string>();
        res.modules = node["modules"].as<decltype(res.modules)>();
        return true;
    }
};

};

namespace YAML {

#define STATE_CELL_CONV_DEF(type) \
    template<> \
    struct convert<type> \
    { \
        static Node encode(const type &rhs) \
        { \
            return rhs.encode(); \
        } \
        static bool decode(const Node& node, type& rhs) \
        { \
            return type::decode(node, rhs); \
        } \
    };

STATE_CELL_CONV_DEF(Emu::RegInfo)
STATE_CELL_CONV_DEF(Emu::RegArrayInfo)
STATE_CELL_CONV_DEF(Emu::CellInfo)
STATE_CELL_CONV_DEF(Emu::ModuleInfo)
STATE_CELL_CONV_DEF(Emu::DesignInfo)

#undef STATE_CELL_CONV_DEF

};

#endif // #ifndef _EMU_DESIGN_INFO_H_
