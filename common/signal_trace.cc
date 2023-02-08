#include "signal_trace.h"

#include <cereal/types/map.hpp>
#include <cereal/types/vector.hpp>
#include <cereal/archives/json.hpp>

using namespace REMU;

#define NVP(name) cereal::make_nvp(#name, node.name)

namespace cereal {

template<class Archive>
void serialize(Archive &archive, SignalTraceData &node)
{
    archive(
        NVP(tick),
        NVP(index),
        NVP(data)
    );
}

template<class Archive>
void serialize(Archive &archive, SignalTraceList &node)
{
    archive(
        NVP(list)
    );
}

} // namespace cereal

std::ostream& REMU::operator<<(std::ostream &stream, const SignalTraceList &info)
{
    cereal::JSONOutputArchive archive(stream);
    archive(cereal::make_nvp("signal_trace", info));
    return stream;
}

std::istream& REMU::operator>>(std::istream &stream, SignalTraceList &info)
{
    cereal::JSONInputArchive archive(stream);
    archive(cereal::make_nvp("signal_trace", info));
    return stream;
}
