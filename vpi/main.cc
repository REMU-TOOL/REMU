#include "replay.h"

static void replay_startup_routine() {
    s_vpi_vlog_info vlog_info;
    vpi_get_vlog_info(&vlog_info);

    std::vector<std::string> args;
    char **p = vlog_info.argv, **end = vlog_info.argv + vlog_info.argc;
    while (p != end) {
        args.push_back(*p++);
    }

    loader_main(args);
    rammodel_main(args);
}

void (*vlog_startup_routines[])() = {
    replay_startup_routine,
    0
};
