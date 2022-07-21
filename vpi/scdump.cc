#include "loader.h"
#include <iostream>

using namespace Replay;

int main(int argc, const char *argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <sc_file> <ckpt_path>" << std::endl;
        return 1;
    }

    std::string sc_file = argv[1];
    std::string ckpt_path = argv[2];

    Checkpoint ckpt(ckpt_path);
    PrintLoader loader(sc_file, ckpt);

    return loader.load() ? 0 : 1;
}
