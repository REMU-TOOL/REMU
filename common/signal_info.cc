#include "signal_info.h"

#include <cereal/types/map.hpp>
#include <cereal/types/vector.hpp>
#include <cereal/archives/json.hpp>

using namespace REMU;

#define NVP(name) cereal::make_nvp(#name, node.name)

namespace cereal {

template<class Archive>
void serialize(Archive &archive, SignalState &node)
{
    archive(
        NVP(tick),
        NVP(index),
        NVP(data)
    );
}

} // namespace cereal

std::ostream& REMU::operator<<(std::ostream &stream, const SignalStateList &info)
{
    cereal::JSONOutputArchive archive(stream);
    archive(cereal::make_nvp("list", info));
    return stream;
}

std::istream& REMU::operator>>(std::istream &stream, SignalStateList &info)
{
    cereal::JSONInputArchive archive(stream);
    archive(cereal::make_nvp("list", info));
    return stream;
}
