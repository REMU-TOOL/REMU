#include "circuit.h"

#include <cstring>
#include <iostream>

#include "escape.h"

using namespace REMU;

void print_path(const std::vector<std::string> &path)
{
    bool first = true;
    for (auto &name : path) {
        if (first)
            first = false;
        else
            std::cout << ".";
        std::cout << Escape::escape_verilog_id(name);
    }
}

void print_circuit(const CircuitState &circuit)
{
    for (auto &it : circuit.wire) {
        print_path(it.first);
        std::cout << " = " << it.second.width() << "'h" << it.second.hex() << std::endl;
    }
    for (auto &it : circuit.ram) {
        int width = it.second.width();
        int depth = it.second.depth();
        int start_offset = it.second.start_offset();
        for (int i = 0; i < depth; i++) {
            auto word = it.second.get(i);
            print_path(it.first);
            std::cout << "[" << i + start_offset << "] = " << word.width() << "'h" << word.hex() << std::endl;
        }
    }
}

int main(int argc, const char *argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <sysinfo_file> <ckpt_path>" << std::endl;
        return 1;
    }

    std::string sysinfo_file = argv[1];
    std::string ckpt_path = argv[2];

    SysInfo sysinfo;
    std::ifstream f(sysinfo_file);
    if (f.fail()) {
        fprintf(stderr, "Can't open file `%s': %s\n", sysinfo_file.c_str(), strerror(errno));
        return 1;
    }
    f >> sysinfo;

    Checkpoint ckpt(ckpt_path);

    CircuitState circuit(sysinfo);
    circuit.load(ckpt);

    print_circuit(circuit);

    return 0;
}
