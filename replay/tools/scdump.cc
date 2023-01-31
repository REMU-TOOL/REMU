#include "circuit.h"
#include <iostream>

#include "escape.h"

using namespace REMU;

void print_circuit(CircuitInfo *circuit, std::string prefix = "")
{
    for (auto &it : circuit->regs) {
        auto name = Escape::escape_verilog_id(it.first);
        std::cout << prefix << name
            << " = " << it.second.data.width() << "'h" << it.second.data.hex() << std::endl;
    }
    for (auto &it : circuit->regarrays) {
        auto name = Escape::escape_verilog_id(it.first);
        int width = it.second.data.width();
        int depth = it.second.data.depth();
        int start_offset = it.second.start_offset;
        for (int i = 0; i < depth; i++) {
            auto word = it.second.data.get(i);
            std::cout << prefix << name
                << "[" << i + start_offset << "] = " << word.width() << "'h" << word.hex() << std::endl;
        }
    }
    for (auto it : circuit->cells) {
        auto name = Escape::escape_verilog_id(it.first);
        print_circuit(it.second, prefix + name + ".");
    }
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

    CircuitInfo circuit(config);
    CircuitLoader loader(config, circuit);
    loader.load(ckpt);

    print_circuit(&circuit);

    return 0;
}
