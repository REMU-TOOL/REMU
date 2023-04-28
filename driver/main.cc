#include <cstdio>
#include <cstring>

#include <fstream>

#include "emu_info.h"
#include "driver.h"

using namespace REMU;

void show_logo()
{
    fprintf(stderr,
        "_______________________  _______  __\n"
        "___  __ \\__  ____/__   |/  /_  / / /\n"
        "__  /_/ /_  __/  __  /|_/ /_  / / / \n"
        "_  _, _/_  /___  _  /  / / / /_/ /  \n"
        "/_/ |_| /_____/  /_/  /_/  \\____/   \n"
        "                                    \n"
        "\n"
    );
}

void show_help(const char * argv_0)
{
    //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
    fprintf(stderr,
        "Usage: %s <sysinfo_file> <platinfo_file> <checkpoint_path> [options] [commands]\n"
        "\n"
        "    You can specify \"@cosim\" as <platinfo_file> for co-simulation (if enabled).\n"
        "\n"
        "Options:\n"
        "    --batch\n"
        "        Exit after commands are finished.\n"
        "\n"
        , argv_0);
}

int main(int argc, const char *argv[])
{
    show_logo();

    if (argc < 4) {
        show_help(argv[0]);
        return 1;
    }

    int argidx = 1;

    std::string sysinfo_file = argv[argidx++];
    std::string platinfo_file = argv[argidx++];

    DriverParameters options;
    options.ckpt_path = argv[argidx++];

    bool batch = false;

    for (; argidx < argc; argidx++) {
        if (!strcmp(argv[argidx], "--batch")) {
            batch = true;
            continue;
        }
        if (argv[argidx][0] != '-') {
            break;
        }
        fprintf(stderr, "unrecognized option %s\n", argv[argidx]);
        return 1;
    }

    std::vector<std::string> commands(argv + argidx, argv + argc);

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

    if (platinfo_file == "@cosim") {
        platinfo["mem"]["type"] = "cosim";
        platinfo["reg"]["type"] = "cosim";
    }
    else {
        std::ifstream f(platinfo_file);
        if (f.fail()) {
            fprintf(stderr, "Can't open file `%s': %s\n", platinfo_file.c_str(), strerror(errno));
            return 1;
        }
        platinfo = YAML::Load(f);
    }

    Driver driver(sysinfo, platinfo, options);

    return driver.main(commands, batch);
}
