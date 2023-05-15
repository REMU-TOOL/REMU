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
    CheckpointManager ckpt_mgr;
    uint64_t tick;
    Checkpoint ckpt;
    bool suppress_warning;

    VPILoader(const SysInfo &sysinfo, std::string ckpt_path, uint64_t tick) :
        sysinfo(sysinfo), circuit(sysinfo), ckpt_mgr(sysinfo, ckpt_path), tick(tick), ckpt(ckpt_mgr.open(tick)),
        suppress_warning(false)
    {
        circuit.load(ckpt);
    }

    void load();
};

void register_tfs(REMU::VPILoader *loader);
void register_callback(REMU::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
