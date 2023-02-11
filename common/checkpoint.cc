#include "checkpoint.h"

#include <cstdio>

#include <set>
#include <string>
#include <fstream>
#include <filesystem>

#include <cereal/types/set.hpp>
#include <cereal/archives/json.hpp>

namespace fs = std::filesystem;

using namespace REMU;

struct Checkpoint::ImpData
{
    fs::path path;
};

struct CheckpointManager::ImpData
{
    fs::path path;
};

std::ifstream Checkpoint::readMem(std::string name)
{
    return std::ifstream(data->path / "mem" / name, std::ios::binary);
}

std::ofstream Checkpoint::writeMem(std::string name)
{
    return std::ofstream(data->path / "mem" / name, std::ios::binary);
}

uint64_t Checkpoint::getTick()
{
    std::ifstream f(data->path / "tick", std::ios::binary);
    uint64_t tick = 0;
    f.read(reinterpret_cast<char*>(&tick), sizeof(tick));
    return tick;
}

void Checkpoint::setTick(uint64_t tick)
{
    std::ofstream f(data->path / "tick", std::ios::binary);
    f.write(reinterpret_cast<char*>(&tick), sizeof(tick));
}

Checkpoint::Checkpoint(const std::string &path) : data(new ImpData)
{
    data->path = path;
    fs::create_directories(data->path);
}

Checkpoint::~Checkpoint()
{
    delete data;
}

void CheckpointManager::saveTickList()
{
    std::ofstream f(data->path / "ticks.json");
    cereal::JSONOutputArchive archive(f);
    archive << tick_list;
}

void CheckpointManager::loadTickList()
{
    std::ifstream f(data->path / "ticks.json");
    if (f.fail()) {
        tick_list = {};
        return;
    }

    cereal::JSONInputArchive archive(f);
    archive >> tick_list;
}

Checkpoint CheckpointManager::open(uint64_t tick)
{
    tick_list.insert(tick);

    char ckpt_name[32];
    snprintf(ckpt_name, 32, "%020lu", tick);

    auto ckpt_path = data->path / ckpt_name;
    fs::create_directories(ckpt_path);

    return Checkpoint(ckpt_path);
}

SignalTraceDB CheckpointManager::readTrace()
{
    SignalTraceDB res;
    res.record_end = 0;
    auto path = data->path / "trace.json";
    std::ifstream f(path, std::ios::binary);
    if (!f.fail())
        f >> res;
    return res;
}

void CheckpointManager::writeTrace(const SignalTraceDB &db)
{
    auto path = data->path / "trace.json";
    std::ofstream f(path, std::ios::binary);
    f << db;
}

CheckpointManager::CheckpointManager(const std::string &path) : data(new ImpData)
{
    data->path = path;
    fs::create_directories(data->path);
    loadTickList();
}

CheckpointManager::~CheckpointManager()
{
    delete data;
}
