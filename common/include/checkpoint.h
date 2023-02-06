#ifndef _CHECKPOINT_H_
#define _CHECKPOINT_H_

#include <fstream>

namespace REMU {

class Checkpoint
{
    std::string path;

public:

    std::ifstream readItem(std::string item) { return std::ifstream(path + "/" + item, std::ios::binary); }
    std::ofstream writeItem(std::string item) { return std::ofstream(path + "/" + item, std::ios::binary); }

    uint64_t getTick();
    void setTick(uint64_t tick);

    Checkpoint(std::string path) : path(path) {}
};

};

#endif // #ifndef _CHECKPOINT_H_
