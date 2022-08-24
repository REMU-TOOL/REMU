#ifndef _REPLAY_VPI_H_
#define _REPLAY_VPI_H_

#include "checkpoint.h"
#include "loader.h"

namespace Replay {

class VPILoader
{
    YAML::Node config;
    CircuitData circuit;

public:

    VPILoader(std::string config_path, Checkpoint &checkpoint)
    {
        config = YAML::LoadFile(config_path);
        circuit = CircuitData(config);
        CircuitDataLoader loader(config, checkpoint, circuit);
        loader.load();
    }

    void load();
};

void register_tfs(Replay::Checkpoint *checkpoint);
void register_load_callback(Replay::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
