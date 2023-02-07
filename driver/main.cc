#include <cstdio>
#include <cstring>

#include <fstream>

#include "emu_info.h"
#include "scheduler.h"
#include "uma_cosim.h"
#include "uma_devmem.h"

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

    std::unique_ptr<UserMem> mem;
    if (platinfo.mem_type == "cosim")
        mem = std::unique_ptr<UserMem>(new CosimUserMem(platinfo.mem_base, platinfo.mem_size));
    else if (platinfo.mem_type == "devmem")
        mem = std::unique_ptr<UserMem>(new DMUserMem(platinfo.mem_base, platinfo.mem_size, platinfo.mem_dmabase));
    else {
        fprintf(stderr, "PlatInfo error: mem_type %s is not supported\n", platinfo.mem_type.c_str());
        return 1;
    }

    std::unique_ptr<UserIO> reg;
    if (platinfo.reg_type == "cosim")
        reg = std::unique_ptr<UserIO>(new CosimUserIO(platinfo.reg_base));
    else if (platinfo.reg_type == "devmem")
        reg = std::unique_ptr<UserIO>(new DMUserIO(platinfo.reg_base, platinfo.reg_size));
    else {
        fprintf(stderr, "PlatInfo error: reg_type %s is not supported\n", platinfo.reg_type.c_str());
        return 1;
    }

    Scheduler driver(sysinfo, options, std::move(mem), std::move(reg));

    return driver.main();
}
