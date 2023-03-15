#ifndef _CHECKPOINT_H_
#define _CHECKPOINT_H_

#include <fstream>
#include <set>
#include <map>
#include <unordered_set>
#include <unordered_map>

#include "emu_info.h"
#include "bitvector.h"

namespace REMU {

struct CheckpointInfo
{
    std::unordered_set<std::string> input_signals;
    std::unordered_map<std::string, uint64_t> axi_size_map;
    std::unordered_set<std::string> models;
};

class CheckpointMem
{
    std::string mem_path;
    uint64_t mem_size;

public:

    std::ifstream read();
    std::ofstream write();
    void load(std::string file);
    void save(std::string file);

    void flush();

    CheckpointMem(const std::string &path, uint64_t size) :
        mem_path(path), mem_size(size) {}

    ~CheckpointMem() { flush(); }
};

class CheckpointModel
{
    std::string model_path;

public:

    std::ifstream load_data();
    std::ofstream save_data();

    CheckpointModel(const std::string &path) :
        model_path(path) {}
};

class Checkpoint
{
    CheckpointInfo info;
    std::string ckpt_path;

    std::string get_mem_path(std::string name);
    std::string get_model_path(std::string name);

public:

    void flush();

    // SERIALIZABLE DATA BEGIN

    std::multimap<uint64_t, std::string> tick_cbs;

    // SERIALIZABLE DATA END

    std::unordered_map<std::string, CheckpointMem> axi_mems;
    std::unordered_map<std::string, CheckpointModel> models;

    Checkpoint(const CheckpointInfo &info, const std::string &path);

    ~Checkpoint() { flush(); }
};

class CheckpointManager
{
    CheckpointInfo info;
    std::string ckpt_root_path;

public:

    void flush();

    // SERIALIZABLE DATA BEGIN

    std::set<uint64_t> ticks;

    // signal name -> { tick -> data }
    std::map<std::string, std::map<uint64_t, BitVector>> signal_trace;

    // SERIALIZABLE DATA END

    // remove checkpoints & traces after the tick
    void truncate(uint64_t tick);

    bool has_tick(uint64_t tick) { return ticks.find(tick) != ticks.end(); }

    uint64_t last_tick()
    {
        if (ticks.empty())
            return 0;

        return *ticks.rbegin();
    }

    uint64_t find_latest(uint64_t tick)
    {
        auto it = ticks.upper_bound(tick); // the smallest value which is > tick
        if (it == ticks.begin())
            return 0;

        --it; // the previous one is the biggest value which is <= tick

        return *it;
    }

    Checkpoint open(uint64_t tick);

    CheckpointManager(const SysInfo &sysinfo, const std::string &path);
    ~CheckpointManager() { flush(); }
};

};

#endif // #ifndef _CHECKPOINT_H_
