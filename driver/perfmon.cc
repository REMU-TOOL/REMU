#include "perfmon.h"

#include <system_error>

using namespace REMU;

void PerfMon::log(const std::string &reason, uint64_t tick)
{
    using namespace std::literals;
    auto new_time = EmuTime::now(tick);
    auto diff = new_time - prev_time;
    fprintf(log_file, "Tick %lu, Elasped time %.6lfs, Rate %.2lf MHz, TC %lu: %s\n",
        tick,
        (std::chrono::duration<double, std::micro>(diff.timediff) / 1s),
        diff.mhz(),
        triggered_count - prev_triggered_count,
        reason.c_str());
    prev_time = new_time;
    prev_triggered_count = triggered_count;
}

PerfMon::PerfMon(const std::string &filename)
{
    if (filename.empty())
        log_file = stderr;
    else
        log_file = fopen(filename.c_str(), "w");

    if (!log_file)
        throw std::system_error(errno, std::generic_category(), "failed to open " + filename);

    prev_time = EmuTime::now(0);
    triggered_count = 0;
    prev_triggered_count = 0;
}

PerfMon::~PerfMon()
{
    if (log_file != stderr)
        fclose(log_file);
}
