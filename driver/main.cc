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
        "Common options:\n"
        "    --save\n"
        "        Save a checkpoint when execution is stopped.\n"
        "    --to <tick>\n"
        "        Stop execution at the specified tick.\n"
        "\n"
        "Record mode options:\n"
        "    --init-axi-mem <axi_name> <bin_file>\n"
        "        Initialize AXI memory region with the specified file.\n"
        "    --period <period>\n"
        "        Set checkpoint period.\n"
        "    --set-signal <tick> <name> <value>\n"
        "        Set signal value at the specified tick.\n"
        "\n"
        "Replay mode options:\n"
        "    --replay <tick>\n"
        "        Replay from the specified tick. Must be set for replay mode.\n"
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
        if (!strcmp(argv[i], "--save")) {
            options.save = true;
            continue;
        }
        if (!strcmp(argv[i], "--to")) {
            if (argc - i <= 1) {
                fprintf(stderr, "missing arguments for --to\n");
                return 1;
            }
            options.to = std::stoul(argv[++i]);
            continue;
        }
        if (!strcmp(argv[i], "--init-axi-mem")) {
            if (argc - i <= 2) {
                fprintf(stderr, "missing arguments for --init-axi-mem\n");
                return 1;
            }
            auto axi_name = argv[++i];
            auto bin_file = argv[++i];
            options.init_axi_mem[axi_name] = bin_file;
            continue;
        }
        if (!strcmp(argv[i], "--period")) {
            if (argc - i <= 1) {
                fprintf(stderr, "missing arguments for --period\n");
                return 1;
            }
            options.period = std::stoul(argv[++i]);
            continue;
        }
        if (!strcmp(argv[i], "--set-signal")) {
            if (argc - i <= 3) {
                fprintf(stderr, "missing arguments for --set-signal\n");
                return 1;
            }
            auto tick = std::stoul(argv[++i]);
            auto name = argv[++i];
            BitVector value(argv[++i]);
            options.set_signal.push_back({
                .tick   = tick,
                .name   = name,
                .value  = value,
            });
            continue;
        }
        if (!strcmp(argv[i], "--replay")) {
            if (argc - i <= 1) {
                fprintf(stderr, "missing arguments for --replay\n");
                return 1;
            }
            options.replay = std::stoul(argv[++i]);
            continue;
        }
        fprintf(stderr, "unrecognized option %s\n", argv[i]);
        return 1;
    }

    SysInfo sysinfo;
    PlatInfo platinfo;

    {
        std::ifstream f(sysinfo_file);
        if (f.fail()) {
            fprintf(stderr, "Can't open file `%s': %s\n", sysinfo_file.c_str(), strerror(errno));
            return 1;
        }
        f >> sysinfo;
    }

    {
        std::ifstream f(platinfo_file);
        if (f.fail()) {
            fprintf(stderr, "Can't open file `%s': %s\n", platinfo_file.c_str(), strerror(errno));
            return 1;
        }
        f >> platinfo;
    }

    Driver driver(sysinfo, platinfo, options);

    return driver.main();
}
