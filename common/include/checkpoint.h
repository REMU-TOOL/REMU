#ifndef _CHECKPOINT_H_
#define _CHECKPOINT_H_

#include <set>
#include <fstream>

namespace REMU {

class Checkpoint
{
    struct ImpData;
    ImpData *data;

public:

    std::ifstream readMem(std::string name);
    std::ofstream writeMem(std::string name);

    uint64_t getTick();
    void setTick(uint64_t tick);

    Checkpoint(const std::string &path);
    ~Checkpoint();
};

class CheckpointManager
{
    struct ImpData;
    ImpData *data;

    std::set<uint64_t> tick_list;

    void saveTickList();
    void loadTickList();

public:

    bool exists(uint64_t tick) { return tick_list.find(tick) != tick_list.end(); }

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
    ~CheckpointManager();
};

};

#endif // #ifndef _CHECKPOINT_H_
