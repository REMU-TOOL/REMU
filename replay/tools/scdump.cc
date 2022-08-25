#include "circuit.h"
#include <iostream>

using namespace Replay;

void print_scope(const CircuitDataScope &circuit, std::string prefix)
{
    prefix += circuit.scope.name + ".";
    for (auto it : circuit.scope) {
        auto node = it.second;
        if (node->type() == CircuitInfo::NODE_SCOPE) {
            auto scope = dynamic_cast<CircuitInfo::Scope*>(node);
            if (scope == nullptr)
                throw std::bad_cast();
            print_scope(circuit.subscope({scope->name}), prefix);
        }
        else if (node->type() == CircuitInfo::NODE_WIRE) {
            auto wire = dynamic_cast<CircuitInfo::Wire*>(node);
            if (wire == nullptr)
                throw std::bad_cast();
            auto &data = circuit.ff(wire->id);
            std::cout << prefix << wire->name
                << " = " << data.width() << "'h" << data.hex() << std::endl;
        }
        else if (node->type() == CircuitInfo::NODE_MEM) {
            auto mem = dynamic_cast<CircuitInfo::Mem*>(node);
            if (mem == nullptr)
                throw std::bad_cast();
            int width = mem->width;
            int depth = mem->depth;
            int start_offset = mem->start_offset;
            auto &data = circuit.mem(mem->id);
            for (int i = 0; i < depth; i++) {
                auto word = data.get(i);
                std::cout << prefix << mem->name
                    << "[" << i + start_offset << "] = " << word.width() << "'h" << word.hex() << std::endl;
            }
        }
    }
}

void print_circuit(const CircuitData &circuit)
{
    print_scope(circuit, "");
}

int main(int argc, const char *argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <cfg_file> <ckpt_path>" << std::endl;
        return 1;
    }

    std::string cfg_file = argv[1];
    std::string ckpt_path = argv[2];

    YAML::Node config;
    try {
        config = YAML::LoadFile(cfg_file);
    }
    catch (YAML::BadFile &e) {
        std::cerr << "ERROR: Cannot load yaml file " << cfg_file << std::endl;
        return false;
    }


    Checkpoint ckpt(ckpt_path);

    CircuitData circuit(config);
    CircuitDataLoader loader(config, ckpt, circuit);
    loader.load();

    print_circuit(circuit);

    return 0;
}
