#include "replay_vpi.h"

#include <cstring>
#include <vpi_user.h>

using namespace REMU;

void replay_startup_routine() {
    s_vpi_vlog_info vlog_info;
    vpi_get_vlog_info(&vlog_info);

    std::vector<std::string> args;
    char **p = vlog_info.argv, **end = vlog_info.argv + vlog_info.argc;
    while (p != end) {
        args.push_back(*p++);
    }

    std::string sysinfo_file, checkpoint_path;
    for (size_t i = 0; i < args.size(); i++) {
        if (args[i] == "-sysinfo" && i+1 < args.size()) {
            sysinfo_file = args[++i];
        }
        if (args[i] == "-checkpoint" && i+1 < args.size()) {
            checkpoint_path = args[++i];
        }
    }

    if (checkpoint_path.empty()) {
        vpi_printf("ERROR: checkpoint path not specified\n");
        return;
    }

    if (sysinfo_file.empty()) {
        vpi_printf("ERROR: sysinfo file not specified\n");
        return;
    }

    SysInfo sysinfo;
    std::ifstream f(sysinfo_file);
    if (f.fail()) {
        fprintf(stderr, "Can't open file `%s': %s\n", sysinfo_file.c_str(), strerror(errno));
        return;
    }
    f >> sysinfo;

    auto loader = new VPILoader(sysinfo, checkpoint_path);

    register_tfs(loader);
    register_load_callback(loader);
}

void (*vlog_startup_routines[])() = {
    replay_startup_routine,
    0
};
