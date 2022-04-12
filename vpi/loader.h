#ifndef _LOADER_H_
#define _LOADER_H_

#include "checkpoint.h"
#include "yaml-cpp/yaml.h"

namespace Replay {

class Loader {
    std::string m_sc_file;
    Checkpoint &m_checkpoint;

public:
    bool load();
    Loader(std::string sc_file, Checkpoint &checkpoint)
        : m_sc_file(sc_file), m_checkpoint(checkpoint) {}
};

};

#endif // #ifndef _LOADER_H_
