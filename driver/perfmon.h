#ifndef _REMU_PERFMON_H_
#define _REMU_PERFMON_H_

#include <cstdio>
#include <string>
#include <chrono>

namespace REMU {

struct EmuTimeDiff
{
    std::chrono::nanoseconds timediff;
    int64_t tickdiff;

    double mhz() const
    {
        using namespace std::literals;
        return static_cast<double>(tickdiff) / (timediff / 1us);
    }

    EmuTimeDiff(decltype(timediff) timediff, decltype(tickdiff) tickdiff)
        : timediff(timediff), tickdiff(tickdiff) {}
};

struct EmuTime
{
    std::chrono::time_point<std::chrono::steady_clock> time;
    uint64_t tick;

    EmuTimeDiff operator-(const EmuTime &other) const
    {
        return EmuTimeDiff(
            time - other.time,
            tick - other.tick);
    }

    static EmuTime now(uint64_t tick)
    {
        return EmuTime(std::chrono::steady_clock::now(), tick);
    }

    EmuTime() = default;
    EmuTime(decltype(time) time, decltype(tick) tick)
        : time(time), tick(tick) {}
};

struct PerfMon
{
    FILE *log_file;
    EmuTime prev_time;

    void log(const std::string &reason, uint64_t tick);

    PerfMon(const std::string &filename, uint64_t tick);
    ~PerfMon();
};

}

#endif
