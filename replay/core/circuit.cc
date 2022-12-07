#include "circuit.h"
#include <sstream>
#include <queue>

#include <cstdio>

using namespace Replay;

namespace {

// https://stackoverflow.com/questions/1392059/algorithm-to-generate-bit-mask
template <typename R>
constexpr R bitmask(unsigned int const onecount)
{
    return static_cast<R>(-(onecount != 0))
        & (static_cast<R>(-1) >> ((sizeof(R) * 8) - onecount));
}

std::vector<std::string> name_from_yaml(const YAML::Node &node)
{
    std::vector<std::string> name;
    for (auto it = node.begin(); it != node.end(); ++it) {
        const YAML::Node &term = *it;
        name.push_back(term.as<std::string>());
    }
    return name;
}

}; // namespace

void CircuitLoader::load(Checkpoint &checkpoint)
{
    GzipReader reader(checkpoint.get_file_path("scanchain"));
    if (reader.fail()) {
        std::cerr << "ERROR: Can't open scanchain file" << std::endl;
        return;
    }

    std::istream data_stream(reader.streambuf());

    const YAML::Node &ff_list = config["ff"];
    size_t ff_size = 0, ff_offset = 0;
    for (auto &ff : ff_list)
        ff_size += ff["width"].as<int>();

    BitVector ff_data(ff_size);
    data_stream.read(reinterpret_cast<char *>(ff_data.to_ptr()), (ff_size + 63) / 64 * 8);

    for (auto &ff : ff_list) {
        auto name = name_from_yaml(ff["name"]);
        int width = ff["width"].as<int>();
        int offset = ff["offset"].as<int>();
        auto &reg = circuit.reg(name);
        reg.data.setValue(offset, ff_data.getValue(ff_offset, width));
        ff_offset += width;
    }

    const YAML::Node &ram_list = config["ram"];
    size_t ram_size = 0, ram_offset = 0;
    for (auto &ram : ram_list)
        ram_size += ram["width"].as<int>() * ram["depth"].as<int>();

    BitVector ram_data(ram_size);
    data_stream.read(reinterpret_cast<char *>(ram_data.to_ptr()), (ram_size + 63) / 64 * 8);

    for (auto &ram : ram_list) {
        auto name = name_from_yaml(ram["name"]);
        int width = ram["width"].as<int>();
        int depth = ram["depth"].as<int>();
        auto &regarray = circuit.regarray(name);
        for (int i = 0; i < depth; i++) {
            regarray.data.set(i, ram_data.getValue(ram_offset, width));
            ram_offset += width;
        }
    }
}
