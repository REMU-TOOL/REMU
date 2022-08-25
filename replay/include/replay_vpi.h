#ifndef _REPLAY_VPI_H_
#define _REPLAY_VPI_H_

#include "checkpoint.h"
#include "circuit.h"
#include <memory>

#include "vpi_user.h"

namespace Replay {

struct VPILoader
{
    YAML::Node config;
    std::unique_ptr<CircuitData> circuit;
    Checkpoint checkpoint;

    VPILoader(std::string config_path, std::string ckpt_path) : checkpoint(ckpt_path)
    {
        config = YAML::LoadFile(config_path);
        circuit = std::unique_ptr<CircuitData>(new CircuitData(config));
        CircuitDataLoader loader(config, checkpoint, *circuit);
        loader.load();
    }

    void load();
};

void register_tfs(Replay::VPILoader *loader);
void register_load_callback(Replay::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
