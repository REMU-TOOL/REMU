#include <cstdio>
#include <cstring>

#include <fstream>

#include "emu_info.h"
#include "driver.h"

using namespace REMU;

void show_help(const char * argv_0)
{
    fprintf(stderr,
        "Usage: %s <sysinfo_file> <platinfo_file> [options]\n"
        "Options:\n"
        "    --init-axi-mem <axi_name> <bin_file>\n"
        "        Initialize AXI memory region with specified file\n"
        , argv_0);
}

int main(int argc, const char *argv[])
{
    if (argc < 3) {
        show_help(argv[0]);
        return 1;
    }

    std::string sysinfo_file = argv[1];
    std::string platinfo_file = argv[2];

    DriverOptions options;
    for (int i = 3; i < argc; i++) {
        if (!strcmp(argv[i], "--init-axi-mem")) {
            if (argc - i <= 2) {
                fprintf(stderr, "missing arguments for --init-axi-mem\n");
                return 1;
            }
            auto axi_name = argv[++i];
            auto bin_file = argv[++i];
            options.init_axi_mem[axi_name] = bin_file;
        }
        else {
            fprintf(stderr, "unrecognized option %s\n", argv[i]);
            return 1;
        }
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

    int rst_index = driver.lookup_signal("rst");

    driver.schedule_event(new SignalEvent(0, rst_index, BitVector(1, 1)));
    driver.schedule_event(new SignalEvent(10, rst_index, BitVector(1, 0)));
    driver.schedule_event(new StopEvent(10000));

    driver.event_loop();

    std::string trace_file = "trace.json";
    {
        std::ofstream f(trace_file);
        if (f.fail()) {
            fprintf(stderr, "Can't open file `%s': %s\n", trace_file.c_str(), strerror(errno));
            return 1;
        }
        f << driver.signal_trace;
    }

    return 0;
}
