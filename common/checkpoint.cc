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

std::string Checkpoint::getMemPath(std::string name)
{
    return fs::path(ckpt_path) / "mem" / name;
}

std::ifstream Checkpoint::readMem(std::string name)
{
    return std::ifstream(getMemPath(name), std::ios::binary);
}

std::ofstream Checkpoint::writeMem(std::string name)
{
    return std::ofstream(getMemPath(name), std::ios::binary);
}

void Checkpoint::importMem(std::string name, std::string file)
{
    fs::copy_file(file, getMemPath(name));
}

void Checkpoint::exportMem(std::string name, std::string file)
{
    fs::copy_file(getMemPath(name), file);
}

void Checkpoint::truncMem(std::string name, size_t size)
{
    fs::resize_file(getMemPath(name), size);
}

SignalTraceDB Checkpoint::readTrace()
{
    SignalTraceDB res;
    auto path = fs::path(ckpt_path) / "trace.json";
    std::ifstream f(path, std::ios::binary);
    if (!f.fail())
        f >> res;
    return res;
}

void Checkpoint::writeTrace(const SignalTraceDB &db)
{
    auto path = fs::path(ckpt_path) / "trace.json";
    std::ofstream f(path, std::ios::binary);
    f << db;
}

Checkpoint::Checkpoint(const std::string &path)
{
    ckpt_path = path;
    fs::create_directories(fs::path(path));
    fs::create_directories(fs::path(path) / "mem");
}

void CheckpointManager::saveTickList()
{
    std::ofstream f(fs::path(ckpt_root_path) / "ticks.json");
    cereal::JSONOutputArchive archive(f);
    archive << tick_list;
}

void CheckpointManager::loadTickList()
{
    std::ifstream f(fs::path(ckpt_root_path) / "ticks.json");
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

    auto ckpt_path = fs::path(ckpt_root_path) / ckpt_name;
    fs::create_directories(ckpt_path);

    return Checkpoint(ckpt_path);
}

CheckpointManager::CheckpointManager(const std::string &path)
{
    ckpt_root_path = path;
    fs::create_directories(fs::path(path));
    loadTickList();
}
