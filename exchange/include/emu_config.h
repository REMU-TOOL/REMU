#ifndef _CONFIG_H_
#define _CONFIG_H_

#include <boost/preprocessor.hpp>
#include "yaml-cpp/yaml.h"

namespace Emu {

struct ConfigNode
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
    using type##_field0 = ConfigNode; \
    BOOST_PP_SEQ_FOR_EACH_I(CONFIG_DEF_STRUCT_EACH, type, BOOST_PP_VARIADIC_TO_SEQ(__VA_ARGS__)) \
    using type = BOOST_PP_SEQ_CAT((type##_field)(BOOST_PP_VARIADIC_SIZE(__VA_ARGS__))); \

using ConfigPath = std::vector<std::string>;

CONFIG_DEF_STRUCT(FFConfig,
    (ConfigPath)    (name),
    (int)           (width),
    (int)           (offset),
    (int)           (wire_width),
    (int)           (wire_start_offset),
    (bool)          (wire_upto),
    (bool)          (is_src)
)

CONFIG_DEF_STRUCT(RAMConfig,
    (ConfigPath)    (name),
    (int)           (width),
    (int)           (depth),
    (int)           (start_offset),
    (bool)          (dissolved)
)

CONFIG_DEF_STRUCT(ClockConfig,
    (ConfigPath)    (path),
    (std::string)   (orig_name),
    (std::string)   (port_name),
    // TODO: frequency, phase, etc.
    (int)           (index)
)

CONFIG_DEF_STRUCT(ResetConfig,
    (ConfigPath)    (path),
    (std::string)   (orig_name),
    (std::string)   (port_name),
    // TODO: duration, etc.
    (int)           (index)
)

CONFIG_DEF_STRUCT(TrigConfig,
    (ConfigPath)    (path),
    (std::string)   (orig_name),
    (std::string)   (port_name),
    (std::string)   (desc),
    (int)           (index)
)

CONFIG_DEF_STRUCT(FifoPortConfig,
    (ConfigPath)    (path),
    (std::string)   (orig_name),
    (std::string)   (port_name),
    (int)           (type),
    (int)           (width),
    (int)           (index)
)

CONFIG_DEF_STRUCT(AXIConfig,
    (ConfigPath)    (path),
    (std::string)   (orig_name),
    (std::string)   (port_name),
    (std::string)   (addr_space),
    (int)           (addr_pages)
)

CONFIG_DEF_STRUCT(ModelConfig,
    (ConfigPath)    (path),
    (std::string)   (name),
    (std::string)   (type)
)

CONFIG_DEF_STRUCT(Config,
    (std::vector<FFConfig>)         (ff),
    (std::vector<RAMConfig>)        (ram),
    (std::vector<ClockConfig>)      (clock),
    (std::vector<ResetConfig>)      (reset),
    (std::vector<TrigConfig>)       (trig),
    (std::vector<FifoPortConfig>)   (fifo_port),
    (std::vector<AXIConfig>)        (axi),
    (std::vector<ModelConfig>)      (model)
)

#undef CONFIG_FIELD_TYPE
#undef CONFIG_FIELD_NAME
#undef CONFIG_DEF_STRUCT_EACH
#undef CONFIG_DEF_STRUCT

} // namespace Emu

namespace YAML {

#define CONFIG_CONV_DEF(type) \
    template<> \
    struct convert<type> \
    { \
        static Node encode(const type &rhs) \
        { \
            Node node; \
            rhs.toYAML(node); \
            return node; \
        } \
        static bool decode(const Node& node, type& rhs) { \
            rhs.fromYAML(node); \
            return true; \
        } \
    };

CONFIG_CONV_DEF(Emu::FFConfig)
CONFIG_CONV_DEF(Emu::RAMConfig)
CONFIG_CONV_DEF(Emu::ClockConfig)
CONFIG_CONV_DEF(Emu::ResetConfig)
CONFIG_CONV_DEF(Emu::TrigConfig)
CONFIG_CONV_DEF(Emu::FifoPortConfig)
CONFIG_CONV_DEF(Emu::AXIConfig)
CONFIG_CONV_DEF(Emu::ModelConfig)
CONFIG_CONV_DEF(Emu::Config)

#undef CONFIG_CONV_DEF

}; // namespace YAML

#endif // #ifndef _CONFIG_H_
