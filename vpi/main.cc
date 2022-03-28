#include <vpi_user.h>

#include "loader.h"

using namespace Reconstruct;

static void reconstruct_main() {
    s_vpi_vlog_info vlog_info;
    vpi_get_vlog_info(&vlog_info);

    std::vector<std::string> args;
    for (int i = 0; i < vlog_info.argc; i++) {
        args.push_back(vlog_info.argv[i]);
    }

    std::string config_file, data_file;

    for (size_t i = 0; i < args.size(); ++i) {
        if (args[i] == "-scanchain-yml" && i+1 < args.size()) {
            config_file = args[++i];
        }
        if (args[i] == "-scanchain-data" && i+1 < args.size()) {
            data_file = args[++i];
        }
    }

    if (!config_file.empty() && !data_file.empty()) {
        vpi_printf("Scan chain configuration: %s\n", config_file.c_str());
        vpi_printf("Scan chain data: %s\n", data_file.c_str());
        sc_load(config_file, data_file);
    }
}

void (*vlog_startup_routines[])() = {
    reconstruct_main,
    0
};
