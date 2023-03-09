#ifndef _CHECKPOINT_H_
#define _CHECKPOINT_H_

#include <set>
#include <fstream>

#include "signal_info.h"

namespace REMU {

class Checkpoint
{
    std::string ckpt_path;

    std::string getMemPath(std::string name);

public:

    std::ifstream readMem(std::string name);
    std::ofstream writeMem(std::string name);
    void importMem(std::string name, std::string file);
    void exportMem(std::string name, std::string file);
    void truncMem(std::string name, size_t size);

    SignalTraceDB readTrace();
    void writeTrace(const SignalTraceDB &db);

    Checkpoint(const std::string &path);
};

class CheckpointManager
{
    std::string ckpt_root_path;

    std::set<uint64_t> tick_list;

    void saveTickList();
    void loadTickList();

public:

    void clear()
    {
        tick_list.clear();
        saveTickList();
    }

    const std::set<uint64_t>& list()
    {
        return tick_list;
    }

    bool exists(uint64_t tick)
    {
        return tick_list.find(tick) != tick_list.end();
    }

    uint64_t latest()
    {
        if (tick_list.empty())
            return 0;

        return *tick_list.rbegin();
    }

    uint64_t findNearest(uint64_t tick)
    {
        auto it = tick_list.lower_bound(tick); // the smallest value which is >= tick
        if (it == tick_list.end())
            return 0;

        if (*it == tick)
            return tick;

        --it; // if not == tick, the previous one is the biggest value which is < tick
        if (it == tick_list.end())
            return 0;

        return *it;
    }

    Checkpoint open(uint64_t tick);

    CheckpointManager(const std::string &path);
};

};

#endif // #ifndef _CHECKPOINT_H_
