#include "loader.h"

#include <cstdio>

// https://stackoverflow.com/questions/1392059/algorithm-to-generate-bit-mask
template <typename R>
static constexpr R bitmask(unsigned int const onecount)
{
    return static_cast<R>(-(onecount != 0))
        & (static_cast<R>(-1) >> ((sizeof(R) * 8) - onecount));
}

using namespace Replay;

void BaseLoader::load_ff(std::istream &data_stream, YAML::Node &config) {
    const YAML::Node &ff_list = config["ff"];
    for (auto ff_it = ff_list.begin(); ff_it != ff_list.end(); ++ff_it) {
        const YAML::Node &ff = *ff_it;
        uint64_t data;
        data_stream.read(reinterpret_cast<char *>(&data), sizeof(data));

        for (auto chunk_it = ff.begin(); chunk_it != ff.end(); ++chunk_it) {
            const YAML::Node &chunk =  *chunk_it;
            std::string name = chunk["name"].as<std::string>();
            int width = chunk["width"].as<int>();
            int offset = chunk["offset"].as<int>();

            set_ff_value(name, data, width, offset);
            data >>= width;
        }
    }
}

void BaseLoader::load_mem(std::istream &data_stream, YAML::Node &config) {
    const YAML::Node &mem_list = config["mem"];
    for (auto mem_it = mem_list.begin(); mem_it != mem_list.end(); ++mem_it) {
        const YAML::Node &mem = *mem_it;
        std::string name = mem["name"].as<std::string>();
        int width = mem["width"].as<int>();
        int depth = mem["depth"].as<int>();
        int start_offset = mem["start_offset"].as<int>();

        for (int i = 0; i < depth; i++) {
            for (int j = 0; j < width; j += 64) {
                int w = width - j;
                if (w > 64) w = 64;
                uint64_t data;
                data_stream.read(reinterpret_cast<char *>(&data), sizeof(data));

                set_mem_value(name, i + start_offset, data, w, j);
            }
        }
    }
}

bool BaseLoader::load() {
    YAML::Node config;
    try {
        config = YAML::LoadFile(m_sc_file);
    }
    catch (YAML::BadFile &e) {
        std::cerr << "ERROR: Cannot load yaml file" << m_sc_file << std::endl;
        return false;
    }

    GzipReader reader(m_checkpoint.get_file_path("scanchain"));
    if (reader.fail()) {
        std::cerr << "ERROR: Can't open scanchain file" << std::endl;
        return false;
    }

    std::istream data_stream(reader.streambuf());

    // TODO: width

    load_ff(data_stream, config);
    load_mem(data_stream, config);

    return true;
}

void PrintLoader::set_ff_value(std::string name, uint64_t data, int width, int offset) {
    if (name.empty())
        name = "<unknown>";
    printf("%s[%d:%d] = %lx\n",
        name.c_str(),
        width + offset - 1,
        offset,
        data & bitmask<uint64_t>(width)
    );
}

void PrintLoader::set_mem_value(std::string name, int index, uint64_t data, int width, int offset) {
    if (name.empty())
        name = "<unknown>";
    printf("%s[%d][%d:%d] = %lx\n",
        name.c_str(),
        index,
        width + offset - 1,
        offset,
        data & bitmask<uint64_t>(width)
    );
}
