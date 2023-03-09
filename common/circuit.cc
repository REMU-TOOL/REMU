#include "circuit.h"
#include <sstream>
#include <queue>

#include <cstdio>

using namespace REMU;

namespace {

// https://stackoverflow.com/questions/1392059/algorithm-to-generate-bit-mask
template <typename R>
constexpr R bitmask(unsigned int const onecount)
{
    return static_cast<R>(-(onecount != 0))
        & (static_cast<R>(-1) >> ((sizeof(R) * 8) - onecount));
}

}; // namespace

CircuitState::CircuitState(
    const decltype(SysInfo::wire) &wire_info,
    const decltype(SysInfo::ram) &ram_info,
    const decltype(SysInfo::scan_ff) &scan_ff,
    const decltype(SysInfo::scan_ram) &scan_ram
) : scan_ff(scan_ff), scan_ram(scan_ram)
{
    for (auto &it : wire_info) {
        if (it.second.init_zero)
            wire[it.first] = BitVector(it.second.width);
        else
            wire[it.first] = BitVector(it.second.init_data);
    }

    for (auto &it : ram_info) {
        BitVectorArray array(it.second.width, it.second.depth, it.second.start_offset);
        if (!it.second.init_zero)
            array.set_flattened_data(BitVector(it.second.init_data));
        ram[it.first] = array;
    }
}

void CircuitState::load(Checkpoint &checkpoint)
{
    auto data_stream = checkpoint.readMem("scanchain");

    size_t ff_size = 0, ff_offset = 0;
    for (auto &info : scan_ff)
        ff_size += info.width;

    BitVector ff_data(ff_size);
    data_stream.read(reinterpret_cast<char *>(ff_data.to_ptr()), (ff_size + 63) / 64 * 8);

    for (auto &info : scan_ff) {
        if (!info.name.empty()) {
            auto &data = wire.at(info.name);
            data.setValue(info.offset, ff_data.getValue(ff_offset, info.width));
        }
        ff_offset += info.width;
    }

    size_t mem_size = 0, ram_offset = 0;
    for (auto &info : scan_ram)
        mem_size += info.width * info.depth;

    BitVector ram_data(mem_size);
    data_stream.read(reinterpret_cast<char *>(ram_data.to_ptr()), (mem_size + 63) / 64 * 8);

    for (auto &info : scan_ram) {
        auto &data = ram.at(info.name);
        for (int i = 0; i < info.depth; i++) {
            data.set(data.start_offset() + i, ram_data.getValue(ram_offset, info.width));
            ram_offset += info.width;
        }
    }
}

void CircuitState::save(Checkpoint &checkpoint)
{
    auto data_stream = checkpoint.writeMem("scanchain");

    size_t ff_size = 0, ff_offset = 0;
    for (auto &info : scan_ff)
        ff_size += info.width;

    BitVector ff_data(ff_size);

    for (auto &info : scan_ff) {
        if (!info.name.empty()) {
            auto &data = wire.at(info.name);
            ff_data.setValue(ff_offset, data.getValue(info.offset, info.width));
        }
        ff_offset += info.width;
    }
    data_stream.write(reinterpret_cast<char *>(ff_data.to_ptr()), (ff_size + 63) / 64 * 8);

    size_t mem_size = 0, ram_offset = 0;
    for (auto &info : scan_ram)
        mem_size += info.width * info.depth;

    BitVector ram_data(mem_size);

    for (auto &info : scan_ram) {
        auto &data = ram.at(info.name);
        for (int i = 0; i < info.depth; i++) {
            ram_data.setValue(ram_offset, data.get(data.start_offset() + i));
            ram_offset += info.width;
        }
    }
    data_stream.write(reinterpret_cast<char *>(ram_data.to_ptr()), (mem_size + 63) / 64 * 8);

    size_t pos = data_stream.tellp();
    size_t pad_len = -pos & 0xfff;
    const std::string pad(pad_len, '\0');
    data_stream.write(pad.c_str(), pad.size());
}
