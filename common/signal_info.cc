#include "signal_info.h"

#include <cereal/types/map.hpp>
#include <cereal/archives/json.hpp>

using namespace REMU;

#define NVP(name) cereal::make_nvp(#name, node.name)

namespace cereal {

template<class Archive>
void serialize(Archive &archive, SignalTraceDB &node)
{
    archive(
        NVP(trace_data),
        NVP(record_end)
    );
}

} // namespace cereal

std::ostream& REMU::operator<<(std::ostream &stream, const SignalTraceDB &info)
{
    cereal::JSONOutputArchive archive(stream);
    archive(info);
    return stream;
}

std::istream& REMU::operator>>(std::istream &stream, SignalTraceDB &info)
{
    cereal::JSONInputArchive archive(stream);
    archive(info);
    return stream;
}
