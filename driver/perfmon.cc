#include "perfmon.h"

#include <system_error>

using namespace REMU;

void PerfMon::log(const std::string &reason, uint64_t tick)
{
    using namespace std::literals;
    auto new_time = EmuTime::now(tick);
    auto diff = new_time - prev_time;
    fprintf(log_file, "Tick %lu, Elasped time %.6lfs, Rate %.2lf MHz: %s\n",
        tick, reason.c_str(),
        (std::chrono::duration<double, std::micro>(diff.timediff) / 1s),
        diff.mhz());
    prev_time = new_time;
}

PerfMon::PerfMon(const std::string &filename, uint64_t tick)
{
    if (filename.empty())
        log_file = stderr;
    else
        log_file = fopen(filename.c_str(), "w");

    if (!log_file)
        throw std::system_error(errno, std::generic_category(), "failed to open " + filename);

    prev_time = EmuTime::now(tick);
}

PerfMon::~PerfMon()
{
    if (log_file != stderr)
        fclose(log_file);
}
