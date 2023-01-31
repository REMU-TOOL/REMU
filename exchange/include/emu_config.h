#ifndef _CONFIG_H_
#define _CONFIG_H_

#include <boost/preprocessor.hpp>
#include "yaml-cpp/yaml.h"

namespace REMU {
namespace Config {

template <typename T>
struct _int_type {
    T data;
    _int_type() : data(0) {}
    _int_type(T data) : data(data) {}
    void operator=(T data) { this->data = data; }
    operator T() const { return data; }
};

using u32 = _int_type<uint32_t>;
using u64 = _int_type<uint64_t>;

struct Node
{
    void fromYAML(const YAML::Node &) {}
    void toYAML(YAML::Node &) const {}
};

#define CONFIG_PAIR_FIRST(x) CONFIG_PAIR_FIRST_1 x
#define CONFIG_PAIR_FIRST_1(...) __VA_ARGS__ CONFIG_PAIR_FIRST_2
#define CONFIG_PAIR_FIRST_2(...)
#define CONFIG_PAIR_SECOND(x) CONFIG_PAIR_SECOND_1 x
#define CONFIG_PAIR_SECOND_1(...) CONFIG_PAIR_SECOND_2
#define CONFIG_PAIR_SECOND_2(...) __VA_ARGS__

#define CONFIG_DEF_STRUCT_DECL_EACH(r, type, i, field) \
    CONFIG_PAIR_FIRST(field) CONFIG_PAIR_SECOND(field);

#define CONFIG_DEF_STRUCT_FROM_YAML_EACH(r, type, i, field) \
    CONFIG_PAIR_SECOND(field) = node[BOOST_PP_STRINGIZE(CONFIG_PAIR_SECOND(field))].as<CONFIG_PAIR_FIRST(field)>();

#define CONFIG_DEF_STRUCT_TO_YAML_EACH(r, type, i, field) \
    node[BOOST_PP_STRINGIZE(CONFIG_PAIR_SECOND(field))] = CONFIG_PAIR_SECOND(field);

#define CONFIG_DEF_STRUCT(type, ...) \
    struct type { \
        BOOST_PP_SEQ_FOR_EACH_I(CONFIG_DEF_STRUCT_DECL_EACH, type, BOOST_PP_VARIADIC_TO_SEQ(__VA_ARGS__)) \
        void fromYAML(const YAML::Node &node) { \
            BOOST_PP_SEQ_FOR_EACH_I(CONFIG_DEF_STRUCT_FROM_YAML_EACH, type, BOOST_PP_VARIADIC_TO_SEQ(__VA_ARGS__)) \
        } \
        void toYAML(YAML::Node &node) const { \
            BOOST_PP_SEQ_FOR_EACH_I(CONFIG_DEF_STRUCT_TO_YAML_EACH, type, BOOST_PP_VARIADIC_TO_SEQ(__VA_ARGS__)) \
        } \
    };

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
    (std::string)               (port_name),
    // TODO: frequency, phase, etc.
    (int)                       (index)
)

CONFIG_DEF_STRUCT(Reset,
    (std::vector<std::string>)  (name),
    (std::string)               (port_name),
    // TODO: duration, etc.
    (int)                       (index)
)

CONFIG_DEF_STRUCT(Trig,
    (std::vector<std::string>)  (name),
    (std::string)               (port_name),
    (std::string)               (desc),
    (int)                       (index)
)

CONFIG_DEF_STRUCT(Pipe,
    (std::vector<std::string>)  (name),
    (std::string)               (port_name),
    (std::string)               (type),
    (bool)                      (output),
    (int)                       (width),
    (u32)                       (reg_offset)
)

CONFIG_DEF_STRUCT(AXIPort,
    (std::vector<std::string>)  (name),
    (std::string)               (port_name),
    (u64)                       (size),
    (u32)                       (reg_offset)
)

CONFIG_DEF_STRUCT(Model,
    (std::vector<std::string>)  (name),
    (std::string)               (type),
    (std::map<std::string, std::string>)    (str_params),
    (std::map<std::string, int>)            (int_params)
)

CONFIG_DEF_STRUCT(Config,
    (std::vector<FF>)           (ff),
    (std::vector<RAM>)          (ram),
    (std::vector<Clock>)        (clock),
    (std::vector<Reset>)        (reset),
    (std::vector<Trig>)         (trig),
    (std::vector<Pipe>)         (pipe),
    (std::vector<AXIPort>)      (axi),
    (std::vector<Model>)        (model)
)

#undef CONFIG_FIELD_TYPE
#undef CONFIG_FIELD_NAME
#undef CONFIG_DEF_STRUCT_DECL_EACH
#undef CONFIG_DEF_STRUCT_FROM_YAML_EACH
#undef CONFIG_DEF_STRUCT_TO_YAML_EACH
#undef CONFIG_DEF_STRUCT
#undef CONFIG_PAIR_FIRST
#undef CONFIG_PAIR_FIRST_1
#undef CONFIG_PAIR_FIRST_2
#undef CONFIG_PAIR_SECOND
#undef CONFIG_PAIR_SECOND_1
#undef CONFIG_PAIR_SECOND_2

template <typename T>
struct _int_type_convert
{
    static YAML::Node encode(const T &rhs)
    {
        std::ostringstream ss;
        ss << std::hex << "0x" << rhs.data;
        auto s = ss.str();
        return YAML::Node(s);
    }
    static bool decode(const YAML::Node& node, T& rhs)
    {
        return YAML::convert<decltype(rhs.data)>().decode(node, rhs.data);
    }
};

template <typename T>
struct _config_type_convert
{
    static YAML::Node encode(const T &rhs)
    {
        YAML::Node node;
        rhs.toYAML(node);
        return node;
    }
    static bool decode(const YAML::Node& node, T& rhs) {
        rhs.fromYAML(node);
        return true;
    }
};

} // namespace Config
} // namespace REMU

template<> struct YAML::convert<REMU::Config::u32>
    : public REMU::Config::_int_type_convert<REMU::Config::u32> {};
template<> struct YAML::convert<REMU::Config::u64>
    : public REMU::Config::_int_type_convert<REMU::Config::u64> {};

template<> struct YAML::convert<REMU::Config::FF>
    : public REMU::Config::_config_type_convert<REMU::Config::FF> {};
template<> struct YAML::convert<REMU::Config::RAM>
    : public REMU::Config::_config_type_convert<REMU::Config::RAM> {};
template<> struct YAML::convert<REMU::Config::Clock>
    : public REMU::Config::_config_type_convert<REMU::Config::Clock> {};
template<> struct YAML::convert<REMU::Config::Reset>
    : public REMU::Config::_config_type_convert<REMU::Config::Reset> {};
template<> struct YAML::convert<REMU::Config::Trig>
    : public REMU::Config::_config_type_convert<REMU::Config::Trig> {};
template<> struct YAML::convert<REMU::Config::Pipe>
    : public REMU::Config::_config_type_convert<REMU::Config::Pipe> {};
template<> struct YAML::convert<REMU::Config::AXIPort>
    : public REMU::Config::_config_type_convert<REMU::Config::AXIPort> {};
template<> struct YAML::convert<REMU::Config::Model>
    : public REMU::Config::_config_type_convert<REMU::Config::Model> {};
template<> struct YAML::convert<REMU::Config::Config>
    : public REMU::Config::_config_type_convert<REMU::Config::Config> {};

#endif // #ifndef _CONFIG_H_
