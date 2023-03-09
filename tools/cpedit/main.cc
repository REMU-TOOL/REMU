#include <cstring>
#include <fstream>

#include "cpedit.h"

using namespace REMU;

void cmdline_help(const char *argv_0)
{
    //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
    fprintf(stderr,
        "Usage: %s <sysinfo_file> <checkpoint_path> [commands]\n"
        "\n"
        "CLI mode will be started if no commands are specified.\n"
        "\n"
        , argv_0);
}

int main(int argc, const char *argv[])
{
    if (argc < 3) {
        cmdline_help(argv[0]);
        return 1;
    }

    std::string sysinfo_file = argv[1];
    std::string ckpt_path = argv[2];

    SysInfo sysinfo;
    std::ifstream f(sysinfo_file);
    if (f.fail()) {
        fprintf(stderr, "Can't open file `%s': %s\n", sysinfo_file.c_str(), strerror(errno));
        return 1;
    }
    sysinfo = SysInfo::fromJson(f);

    CpEdit cpedit(sysinfo, ckpt_path);

    if (argc == 3) {
        cpedit.run_cli();
        return 0;
    }

    for (int i = 3; i < argc; i++)
        if (!cpedit.execute(argv[i]))
            return 1;

    return 0;
}
