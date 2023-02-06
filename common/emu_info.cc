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
        NVP(upto)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::RAMInfo &node)
{
    archive(
        NVP(width),
        NVP(depth),
        NVP(start_offset),
        NVP(dissolved)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::ClockInfo &node)
{
    archive(
        NVP(index)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::SignalInfo &node)
{
    archive(
        NVP(width),
        NVP(output),
        NVP(reg_offset)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::TriggerInfo &node)
{
    archive(
        NVP(index)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::AXIInfo &node)
{
    archive(
        NVP(size),
        NVP(reg_offset)
    );
}

template<class Archive>
void serialize(Archive &archive, SysInfo::ModelInfo &node)
{
    archive(
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
        NVP(name)
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

template<class Archive>
void serialize(Archive &archive, PlatInfo &node)
{
    archive(
        NVP(mem_type),
        NVP(mem_base),
        NVP(mem_size),
        NVP(reg_type),
        NVP(reg_base),
        NVP(reg_size)
    );
}

} // namespace cereal

std::ostream& REMU::operator<<(std::ostream &stream, const SysInfo &info)
{
    cereal::JSONOutputArchive archive(stream);
    archive(cereal::make_nvp("sysinfo", info));
    return stream;
}

std::istream& REMU::operator>>(std::istream &stream, SysInfo &info)
{
    cereal::JSONInputArchive archive(stream);
    archive(cereal::make_nvp("sysinfo", info));
    return stream;
}

std::ostream& REMU::operator<<(std::ostream &stream, const PlatInfo &info)
{
    cereal::JSONOutputArchive archive(stream);
    archive(cereal::make_nvp("platinfo", info));
    return stream;
}

std::istream& REMU::operator>>(std::istream &stream, PlatInfo &info)
{
    cereal::JSONInputArchive archive(stream);
    archive(cereal::make_nvp("platinfo", info));
    return stream;
}
