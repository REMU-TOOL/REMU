#include "loader.h"
#include "replay_util.h"

using namespace Replay;

namespace {

void load_value(vpiHandle obj, uint64_t data, int width, int offset) {
#if 0
    vpi_printf("%s[%d:%d] = %lx\n",
        vpi_get_str(vpiFullName, obj),
        width + offset - 1,
        offset,
        data & ~(~0UL << width)
    );
#endif

    int size = vpi_get(vpiSize, obj);

    s_vpi_value value;
    value.format = vpiVectorVal;
    vpi_get_value(obj, &value);

    for (int i = 0; i < (size + 31) / 32; i++) {
        auto &aval = value.value.vector[i].aval;
        auto &bval = value.value.vector[i].bval;
        int w = 32 - offset;
        if (w < 0) w = 0;
        if (w > 32) w = 32;
        if (w > width) w = width;
        int mask = (~0 >> (32 - w)) << offset;
        aval = ((data << offset) & mask) | (aval & ~mask);
        bval = bval & ~mask;
        offset -= 32;
        if (offset < 0) offset = 0;
        data >>= w;
        width -= w;
    }

    vpi_put_value(obj, &value, 0, vpiNoDelay);
}

void load_ff(std::istream &data_stream, YAML::Node &config) {
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

            if (!name.empty()) {
                vpiHandle obj;
                obj = vpi_handle_by_name(name.c_str(), 0);
                if (obj == 0) {
                    vpi_printf("WARNING: %s cannot be referenced\n", name.c_str());
                    continue;
                }

                load_value(obj, data, width, offset);
            }

            data >>= width;
        }
    }
}

void load_mem(std::istream &data_stream, YAML::Node &config) {
    const YAML::Node &mem_list = config["mem"];
    for (auto mem_it = mem_list.begin(); mem_it != mem_list.end(); ++mem_it) {
        const YAML::Node &mem = *mem_it;
        std::string name = mem["name"].as<std::string>();
        int width = mem["width"].as<int>();
        int depth = mem["depth"].as<int>();
        int start_offset = mem["start_offset"].as<int>();

        vpiHandle obj = vpi_handle_by_name(name.c_str(), 0);
        if (obj == 0) {
            vpi_printf("WARNING: %s cannot be referenced\n", name.c_str());
        }

        for (int i = 0; i < depth; i++) {
            vpiHandle word = vpi_handle_by_index(obj, i + start_offset);
            if (word == 0) {
                vpi_printf("WARNING: %s[%d] cannot be referenced\n", name.c_str(), i + start_offset);
            }

            for (int j = 0; j < width; j += 64) {
                int w = width - j;
                if (w > 64) w = 64;
                uint64_t data;
                data_stream.read(reinterpret_cast<char *>(&data), sizeof(data));

                load_value(word, data, w, j);
            }
        }
    }
}

}; // namespace

bool Loader::load() {
    YAML::Node config;
    try {
        config = YAML::LoadFile(m_sc_file);
    }
    catch (YAML::BadFile &e) {
        vpi_printf("ERROR: Cannot load yaml file %s\n", m_sc_file.c_str());
        return false;
    }

    GzipReader reader(m_checkpoint.get_file_path("scanchain"));
    if (reader.fail()) {
        vpi_printf("ERROR: Can't open scanchain file\n");
        return false;
    }

    std::istream data_stream(reader.streambuf());

    // TODO: width

    load_ff(data_stream, config);
    load_mem(data_stream, config);

    return true;
}
