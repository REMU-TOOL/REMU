#include "replay_vpi.h"

#include <vpi_user.h>

using namespace Replay;

void replay_startup_routine() {
    s_vpi_vlog_info vlog_info;
    vpi_get_vlog_info(&vlog_info);

    std::vector<std::string> args;
    char **p = vlog_info.argv, **end = vlog_info.argv + vlog_info.argc;
    while (p != end) {
        args.push_back(*p++);
    }

    std::string scanchain_file, checkpoint_path;
    for (size_t i = 0; i < args.size(); i++) {
        if (args[i] == "-replay-scanchain" && i+1 < args.size()) {
            scanchain_file = args[++i];
        }
        if (args[i] == "-replay-checkpoint" && i+1 < args.size()) {
            checkpoint_path = args[++i];
        }
    }

    auto checkpoint =  new Checkpoint(checkpoint_path);
    auto loader = new Loader(scanchain_file, *checkpoint);
    register_tfs(checkpoint);
    register_load_callback(loader);
}

void (*vlog_startup_routines[])() = {
    replay_startup_routine,
    0
};
