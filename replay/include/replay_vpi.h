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
    CircuitInfo *circuit;
    Checkpoint checkpoint;

    VPILoader(std::string config_path, std::string ckpt_path) : checkpoint(ckpt_path)
    {
        config = YAML::LoadFile(config_path);
        circuit = new CircuitInfo(config);
        CircuitLoader loader(config, *circuit);
        loader.load(checkpoint);
    }

    ~VPILoader()
    {
        delete circuit;
    }

    VPILoader(const VPILoader &) = delete;
    VPILoader& operator=(const VPILoader &) = delete;

    void load();
};

void register_tfs(Replay::VPILoader *loader);
void register_load_callback(Replay::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
