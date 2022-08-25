#ifndef _REPLAY_VPI_H_
#define _REPLAY_VPI_H_

#include "checkpoint.h"
#include "circuit.h"
#include <memory>

namespace Replay {

class VPILoader
{
    YAML::Node config;
    std::unique_ptr<CircuitData> circuit;

public:

    VPILoader(std::string config_path, Checkpoint &checkpoint)
    {
        config = YAML::LoadFile(config_path);
        circuit = std::unique_ptr<CircuitData>(new CircuitData(config));
        CircuitDataLoader loader(config, checkpoint, *circuit);
        loader.load();
    }

    void load();
};

void register_tfs(Replay::Checkpoint *checkpoint);
void register_load_callback(Replay::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
