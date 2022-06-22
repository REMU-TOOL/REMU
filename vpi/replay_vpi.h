#ifndef _REPLAY_VPI_H_
#define _REPLAY_VPI_H_

#include "rammodel.h"
#include "checkpoint.h"
#include "vpi_loader.h"

namespace Replay {

void register_tfs(Replay::Checkpoint *checkpoint);
void register_load_callback(Replay::VPILoader *loader);

};

#endif // #ifndef _REPLAY_VPI_H_
