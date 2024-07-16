#include <cstring>
#include <fstream>

#include "parser.h"

using namespace REMU;

void cmdline_help(const char *argv_0)
{
    //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
    fprintf(stderr,
        "Usage: %s <sysinfo_file> <trace_file>\n"        , argv_0);
}

int main(int argc, const char *argv[])
{
    if (argc < 3) {
        cmdline_help(argv[0]);
        return 1;
    }

    std::string sysinfo_file = argv[1];
    std::string trace_path = argv[2];

    SysInfo sysinfo;
    std::ifstream f(sysinfo_file);
    if (f.fail()) {
        fprintf(stderr, "Can't open file `%s': %s\n", sysinfo_file.c_str(), strerror(errno));
        return 1;
    }
    sysinfo = SysInfo::fromJson(f);

    TParser trace_parser(sysinfo, trace_path);

    trace_parser.run();

    return 0;
}
