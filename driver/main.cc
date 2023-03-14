#include <cstdio>
#include <cstring>

#include <fstream>

#include "emu_info.h"
#include "driver.h"

using namespace REMU;

void show_help(const char * argv_0)
{
    //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
    fprintf(stderr,
        "Usage: %s <sysinfo_file> <platinfo_file> <checkpoint_path> [options]\n"
        "Options:\n"
        "    --perf\n"
        "        Enable performance monitor.\n"
        "    --perf-file <file>\n"
        "        Specify performance monitor log file (STDERR by default).\n"
        "    --perf-interval <tick>\n"
        "        Specify performance monitor interval, 0 to disable (0 by default).\n"
        "\n"
        , argv_0);
}

int main(int argc, const char *argv[])
{
    if (argc < 4) {
        show_help(argv[0]);
        return 1;
    }

    std::string sysinfo_file = argv[1];
    std::string platinfo_file = argv[2];

    DriverParameters options;
    options.ckpt_path = argv[3];

    for (int i = 4; i < argc; i++) {
        if (!strcmp(argv[i], "--perf")) {
            options.perf = true;
            continue;
        }
        if (!strcmp(argv[i], "--perf-file")) {
            if (argc - i <= 1) {
                fprintf(stderr, "missing arguments for --perf-file\n");
                return 1;
            }
            options.perf_file = argv[++i];
            continue;
        }
        if (!strcmp(argv[i], "--perf-interval")) {
            if (argc - i <= 1) {
                fprintf(stderr, "missing arguments for --perf-interval\n");
                return 1;
            }
            options.perf_interval = std::stoul(argv[++i]);
            continue;
        }
        fprintf(stderr, "unrecognized option %s\n", argv[i]);
        return 1;
    }

    SysInfo sysinfo;
    YAML::Node platinfo;

    {
        std::ifstream f(sysinfo_file);
        if (f.fail()) {
            fprintf(stderr, "Can't open file `%s': %s\n", sysinfo_file.c_str(), strerror(errno));
            return 1;
        }
        sysinfo = SysInfo::fromJson(f);
    }

    {
        std::ifstream f(platinfo_file);
        if (f.fail()) {
            fprintf(stderr, "Can't open file `%s': %s\n", platinfo_file.c_str(), strerror(errno));
            return 1;
        }
        platinfo = YAML::Load(f);
    }

    Driver driver(sysinfo, platinfo, options);

    return driver.main();
}
