#include "loader.h"
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

void CircuitData::init()
{
    std::queue<const CircuitInfo::Scope*> worklist;
    worklist.push(&root);
    while (!worklist.empty()) {
        auto scope = worklist.front();
        worklist.pop();
        for (auto &it : *scope) {
            auto node = it.second;
            if (node->type() == CircuitInfo::NODE_SCOPE) {
                auto scope = dynamic_cast<CircuitInfo::Scope*>(node);
                if (scope == nullptr)
                    throw std::bad_cast();
                worklist.push(scope);
            }
            else if (node->type() == CircuitInfo::NODE_WIRE) {
                auto wire = dynamic_cast<CircuitInfo::Wire*>(node);
                if (wire == nullptr)
                    throw std::bad_cast();
                ff_data[wire->id] = BitVector(wire->width);
            }
            else if (node->type() == CircuitInfo::NODE_MEM) {
                auto mem = dynamic_cast<CircuitInfo::Mem*>(node);
                if (mem == nullptr)
                    throw std::bad_cast();
                mem_data[mem->id] = BitVectorArray(mem->width, mem->depth);
            }
        }
    }
}

void CircuitDataLoader::load() {
    GzipReader reader(checkpoint.get_file_path("scanchain"));
    if (reader.fail()) {
        std::cerr << "ERROR: Can't open scanchain file" << std::endl;
        return;
    }

    std::istream data_stream(reader.streambuf());
    const YAML::Node &ff_list = config["ff"];
    for (auto ff_it = ff_list.begin(); ff_it != ff_list.end(); ++ff_it) {
        const YAML::Node &ff = *ff_it;
        uint64_t data;
        data_stream.read(reinterpret_cast<char *>(&data), sizeof(data));

        for (auto chunk_it = ff.begin(); chunk_it != ff.end(); ++chunk_it) {
            const YAML::Node &chunk =  *chunk_it;
            auto name = name_from_yaml(chunk["name"]);
            int width = chunk["width"].as<int>();
            int offset = chunk["offset"].as<int>();

            auto &ff_data = circuit.ff(name);
            ff_data.setValue(offset, width, data);

            data >>= width;
        }
    }

    const YAML::Node &mem_list = config["mem"];
    for (auto mem_it = mem_list.begin(); mem_it != mem_list.end(); ++mem_it) {
        const YAML::Node &mem = *mem_it;
        auto name = name_from_yaml(mem["name"]);
        auto node = circuit.scope.get(name);
        auto mem_node = dynamic_cast<const CircuitInfo::Mem*>(node);
        auto &mem_data = circuit.mem(name);
        int width = mem_node->width;
        int depth = mem_node->depth;

        for (int i = 0; i < depth; i++) {
            for (int j = 0; j < width; j += 64) {
                int w = width - j;
                if (w > 64) w = 64;
                uint64_t data;
                data_stream.read(reinterpret_cast<char *>(&data), sizeof(data));

                auto word = mem_data.get(i);
                word.setValue(j, w, data);
                mem_data.set(i, word);
            }
        }
    }
}
