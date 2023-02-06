#ifndef _REPLAY_VPI_H_
#define _REPLAY_VPI_H_

#include "checkpoint.h"
#include "circuit.h"
#include <memory>

#include "vpi_user.h"

namespace REMU {

struct VPILoader
{
    SysInfo sysinfo;
    CircuitState circuit;
    Checkpoint checkpoint;

    VPILoader(const SysInfo &sysinfo, std::string ckpt_path) :
        sysinfo(sysinfo), circuit(sysinfo), checkpoint(ckpt_path)
    {
        circuit.load(checkpoint);
    }

    void load();
};

void register_tfs(REMU::VPILoader *loader);
void register_load_callback(REMU::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
