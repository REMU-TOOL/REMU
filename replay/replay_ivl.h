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
    uint64_t latest_tick;
    Checkpoint checkpoint;
    SignalTraceDB trace;

    VPILoader(const SysInfo &sysinfo, std::string ckpt_path, uint64_t tick) :
        sysinfo(sysinfo), circuit(sysinfo), ckpt_mgr(ckpt_path), tick(tick), checkpoint(ckpt_mgr.open(tick))
    {
        circuit.load(checkpoint);
        latest_tick = ckpt_mgr.latest();
        auto latest_ckpt = ckpt_mgr.open(latest_tick);
        trace = latest_ckpt.readTrace();
    }

    void load();
};

void register_tfs(REMU::VPILoader *loader);
void register_callback(REMU::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
