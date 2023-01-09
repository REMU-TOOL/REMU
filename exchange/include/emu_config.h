#ifndef _CONFIG_H_
#define _CONFIG_H_

#include <boost/preprocessor.hpp>
#include "yaml-cpp/yaml.h"

namespace Emu {
namespace Config {

struct u32 {
    uint32_t data;
    u32() : data(0) {}
    u32(uint32_t data) : data(data) {}
    void operator=(uint32_t data) { data = data; }
    operator uint32_t() const { return data; }
};

struct Node
{
    void fromYAML(const YAML::Node &) {}
    void toYAML(YAML::Node &) const {}
};

#define CONFIG_FIELD_TYPE(field) BOOST_PP_SEQ_ELEM(0, field)
#define CONFIG_FIELD_NAME(field) BOOST_PP_SEQ_ELEM(1, field)

#define CONFIG_DEF_STRUCT_EACH(r, type, i, field) \
    struct BOOST_PP_SEQ_CAT((type##_field)(BOOST_PP_ADD(i, 1))) \
        : public type##_field##i { \
        CONFIG_FIELD_TYPE(field) CONFIG_FIELD_NAME(field); \
        void fromYAML(const YAML::Node &node) { \
            type##_field##i::fromYAML(node); \
            CONFIG_FIELD_NAME(field) = node[BOOST_PP_STRINGIZE(CONFIG_FIELD_NAME(field))] \
                .as<CONFIG_FIELD_TYPE(field)>();\
        } \
        void toYAML(YAML::Node &node) const { \
            type##_field##i::toYAML(node); \
            node[BOOST_PP_STRINGIZE(CONFIG_FIELD_NAME(field))] = CONFIG_FIELD_NAME(field); \
        } \
    };

#define CONFIG_DEF_STRUCT(type, ...) \
    using type##_field0 = Node; \
    BOOST_PP_SEQ_FOR_EACH_I(CONFIG_DEF_STRUCT_EACH, type, BOOST_PP_VARIADIC_TO_SEQ(__VA_ARGS__)) \
    using type = BOOST_PP_SEQ_CAT((type##_field)(BOOST_PP_VARIADIC_SIZE(__VA_ARGS__))); \

CONFIG_DEF_STRUCT(FF,
    (std::vector<std::string>)  (name),
    (int)                       (width),
    (int)                       (offset),
    (int)                       (wire_width),
    (int)                       (wire_start_offset),
    (bool)                      (wire_upto),
    (bool)                      (is_src)
)

CONFIG_DEF_STRUCT(RAM,
    (std::vector<std::string>)  (name),
    (int)                       (width),
    (int)                       (depth),
    (int)                       (start_offset),
    (bool)                      (dissolved)
)

CONFIG_DEF_STRUCT(Clock,
    (std::vector<std::string>)  (name),
    (std::string)               (orig_name),
    (std::string)               (port_name),
    // TODO: frequency, phase, etc.
    (int)                       (index)
)

CONFIG_DEF_STRUCT(Reset,
    (std::vector<std::string>)  (name),
    (std::string)               (orig_name),
    (std::string)               (port_name),
    // TODO: duration, etc.
    (int)                       (index)
)

CONFIG_DEF_STRUCT(Trig,
    (std::vector<std::string>)  (name),
    (std::string)               (orig_name),
    (std::string)               (port_name),
    (std::string)               (desc),
    (int)                       (index)
)

CONFIG_DEF_STRUCT(Pipe,
    (std::vector<std::string>)  (name),
    (std::string)               (orig_name),
    (std::string)               (port_name),
    (std::string)               (type),
    (bool)                      (output),
    (int)                       (width),
    (u32)                       (base_addr)
)

CONFIG_DEF_STRUCT(AXI,
    (std::vector<std::string>)  (name),
    (std::string)               (orig_name),
    (std::string)               (port_name),
    (std::string)               (addr_space),
    (int)                       (addr_pages)
)

CONFIG_DEF_STRUCT(Model,
    (std::vector<std::string>)  (name),
    (std::string)               (name),
    (std::string)               (type)
)

CONFIG_DEF_STRUCT(Config,
    (std::vector<FF>)           (ff),
    (std::vector<RAM>)          (ram),
    (std::vector<Clock>)        (clock),
    (std::vector<Reset>)        (reset),
    (std::vector<Trig>)         (trig),
    (std::vector<Pipe>)         (pipe),
    (std::vector<AXI>)          (axi),
    (std::vector<Model>)        (model)
)

#undef CONFIG_FIELD_TYPE
#undef CONFIG_FIELD_NAME
#undef CONFIG_DEF_STRUCT_EACH
#undef CONFIG_DEF_STRUCT

} // namespace Config
} // namespace Emu

template<>
struct YAML::convert<Emu::Config::u32>
{
    static YAML::Node encode(const Emu::Config::u32 &rhs)
    {
        std::ostringstream ss;
        ss << std::hex << "0x" << rhs.data;
        return Node(ss.str());
    }
    static bool decode(const YAML::Node& node, Emu::Config::u32& rhs)
    {
        return YAML::convert<decltype(rhs.data)>().decode(node, rhs.data);
    }
};

#define CONFIG_CONV_DEF(type) \
    template<> \
    struct YAML::convert<type> \
    { \
        static YAML::Node encode(const type &rhs) \
        { \
            Node node; \
            rhs.toYAML(node); \
            return node; \
        } \
        static bool decode(const YAML::Node& node, type& rhs) { \
            rhs.fromYAML(node); \
            return true; \
        } \
    };

CONFIG_CONV_DEF(Emu::Config::FF)
CONFIG_CONV_DEF(Emu::Config::RAM)
CONFIG_CONV_DEF(Emu::Config::Clock)
CONFIG_CONV_DEF(Emu::Config::Reset)
CONFIG_CONV_DEF(Emu::Config::Trig)
CONFIG_CONV_DEF(Emu::Config::Pipe)
CONFIG_CONV_DEF(Emu::Config::AXI)
CONFIG_CONV_DEF(Emu::Config::Model)
CONFIG_CONV_DEF(Emu::Config::Config)

#undef CONFIG_CONV_DEF

#endif // #ifndef _CONFIG_H_
