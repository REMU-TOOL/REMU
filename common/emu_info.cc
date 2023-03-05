#include "emu_info.h"

#include <cereal/types/map.hpp>
#include <cereal/types/vector.hpp>
#include <cereal/archives/json.hpp>

using namespace REMU;

#define NVP(name) cereal::make_nvp(#name, node.name)

namespace cereal {

template<class Archive>
void serialize(Archive &archive, SysInfo::WireInfo &node)
{
    archive(
        NVP(width),
        NVP(start_offset),
        NVP(upto),
        NVP(init_zero),
        NVP(init_data)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::RAMInfo &node)
{
    archive(
        NVP(width),
        NVP(depth),
        NVP(start_offset),
        NVP(init_zero),
        NVP(init_data),
        NVP(dissolved)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::ClockInfo &node)
{
    archive(
        NVP(name),
        NVP(index)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::SignalInfo &node)
{
    archive(
        NVP(name),
        NVP(width),
        NVP(output),
        NVP(reg_offset)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::TriggerInfo &node)
{
    archive(
        NVP(name),
        NVP(index)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::AXIInfo &node)
{
    archive(
        NVP(name),
        NVP(size),
        NVP(reg_offset)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::ModelInfo &node)
{
    archive(
        NVP(name),
        NVP(type),
        NVP(str_params),
        NVP(int_params)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::ScanFFInfo &node)
{
    archive(
        NVP(name),
        NVP(width),
        NVP(offset)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::ScanRAMInfo &node)
{
    archive(
        NVP(name),
        NVP(width),
        NVP(depth)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo &node)
{
    archive(
        NVP(wire),
        NVP(ram),
        NVP(clock),
        NVP(signal),
        NVP(trigger),
        NVP(axi),
        NVP(model),
        NVP(scan_ff),
        NVP(scan_ram)
    );
}

} // namespace cereal

void SysInfo::toJson(std::ostream &stream)
{
    cereal::JSONOutputArchive archive(stream);
    cereal::serialize(archive, *this);
}

SysInfo SysInfo::fromJson(std::istream &stream)
{
    SysInfo info;
    cereal::JSONInputArchive archive(stream);
    cereal::serialize(archive, info);
    return info;
}
