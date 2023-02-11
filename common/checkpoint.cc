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

SignalTraceDB Checkpoint::readTrace()
{
    SignalTraceDB res;
    auto path = data->path / "trace.json";
    std::ifstream f(path, std::ios::binary);
    if (!f.fail())
        f >> res;
    return res;
}

void Checkpoint::writeTrace(const SignalTraceDB &db)
{
    auto path = data->path / "trace.json";
    std::ofstream f(path, std::ios::binary);
    f << db;
}

Checkpoint::Checkpoint(const std::string &path) : data(new ImpData)
{
    data->path = path;
    fs::create_directories(data->path);
    fs::create_directories(data->path / "mem");
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
    saveTickList();

    char ckpt_name[32];
    snprintf(ckpt_name, 32, "%020lu", tick);

    auto ckpt_path = data->path / ckpt_name;
    fs::create_directories(ckpt_path);

    return Checkpoint(ckpt_path);
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
