#include "checkpoint.h"

#include <cstdio>

#include <set>
#include <string>
#include <fstream>
#include <filesystem>

#include <cereal/types/map.hpp>
#include <cereal/types/set.hpp>
#include <cereal/types/vector.hpp>
#include <cereal/archives/json.hpp>

#include "emu_utils.h"

#define NVP(name) cereal::make_nvp(#name, node.name)

namespace cereal {

template<class Archive>
void serialize(Archive &archive, REMU::Checkpoint &node)
{
    archive(
        NVP(tick_cbs)
    );
}

template<class Archive>
void serialize(Archive &archive, REMU::CheckpointManager &node)
{
    archive(
        NVP(ticks),
        NVP(signal_trace)
    );
}

}

namespace fs = std::filesystem;

using namespace REMU;

static size_t copy_stream(std::istream &in, std::ostream &out, size_t size, size_t buf_size = 0x100000)
{
    size_t xferred = 0;
    auto buf = new char[buf_size];

    while (xferred < size) {
        size_t slice = size > buf_size ? buf_size : size;

        in.read(buf, slice);
        out.write(buf, in.gcount());

        xferred += in.gcount();

        if (in.gcount() < slice)
            break;
    }

    delete[] buf;
    return xferred;
}

std::ifstream CheckpointMem::read()
{
    return std::ifstream(mem_path, std::ios::binary);
}

std::ofstream CheckpointMem::write()
{
    return std::ofstream(mem_path, std::ios::binary);
}

void CheckpointMem::load(std::string file)
{
    std::ifstream in(file, std::ios::binary);
    std::ofstream out(mem_path, std::ios::binary);
    copy_stream(in, out, mem_size);
}

void CheckpointMem::save(std::string file)
{
    std::ifstream in(mem_path, std::ios::binary);
    std::ofstream out(file, std::ios::binary);
    copy_stream(in, out, mem_size);
}

void CheckpointMem::flush()
{
    if (!fs::exists(mem_path)) {
        auto f = write();
        f.close();
    }
    fs::resize_file(mem_path, mem_size);
}

std::ifstream CheckpointModel::load_data()
{
    return std::ifstream(fs::path(model_path) / "data.bin", std::ios::binary);
}

std::ofstream CheckpointModel::save_data()
{
    return std::ofstream(fs::path(model_path) / "data.bin", std::ios::binary);
}

std::string Checkpoint::get_mem_path(std::string name)
{
    return fs::path(ckpt_path) / "mem" / name;
}

std::string Checkpoint::get_model_path(std::string name)
{
    return fs::path(ckpt_path) / "model" / name;
}

void Checkpoint::flush()
{
    std::ofstream f(fs::path(ckpt_path) / "data.json");
    cereal::JSONOutputArchive archive(f);
    cereal::serialize(archive, *this);
}

Checkpoint::Checkpoint(const CheckpointInfo &info, const std::string &path)
    : info(info), ckpt_path(path)
{
    // Create checkpoint directorires

    fs::create_directories(fs::path(ckpt_path));
    fs::create_directories(fs::path(ckpt_path) / "mem");

    // Load or Initialize serializable data

    std::ifstream f(fs::path(ckpt_path) / "data.json");
    if (!f.fail()) {
        cereal::JSONInputArchive archive(f);
        cereal::serialize(archive, *this);
    }

    // Create memory objects

    for (auto &x : info.axi_size_map) {
        axi_mems.try_emplace(x.first, get_mem_path(x.first), x.second);
    }

    // Create model objects

    for (auto &x : info.models) {
        auto path = get_model_path(x);
        fs::create_directories(path);
        models.try_emplace(x, path);
    }
}

void CheckpointManager::flush()
{
    std::ofstream f(fs::path(ckpt_root_path) / "data.json");
    cereal::JSONOutputArchive archive(f);
    cereal::serialize(archive, *this);
}

void CheckpointManager::truncate(uint64_t tick)
{
    auto it = ticks.upper_bound(tick);
    ticks.erase(it, ticks.end());

    for (auto &trace : signal_trace) {
        auto it = trace.second.upper_bound(tick);
        trace.second.erase(it, trace.second.end());
    }
}

Checkpoint CheckpointManager::open(uint64_t tick)
{
    ticks.insert(tick);

    char ckpt_name[32];
    snprintf(ckpt_name, 32, "%020lu", tick);

    auto ckpt_path = fs::path(ckpt_root_path) / ckpt_name;
    fs::create_directories(ckpt_path);

    return Checkpoint(info, ckpt_path);
}

CheckpointManager::CheckpointManager(const SysInfo &sysinfo, const std::string &path)
    : ckpt_root_path(path)
{
    // Initialize checkpoint info

    for (auto &x : sysinfo.signal) {
        if (!x.output) {
            info.input_signals.insert(flatten_name(x.name));
        }
    }

    for (auto &x : sysinfo.axi) {
        info.axi_size_map[flatten_name(x.name)] = x.size;
    }

    for (auto &x : sysinfo.model) {
        info.models.insert(flatten_name(x.name));
    }

    // Create checkpoint directorires

    fs::create_directories(fs::path(ckpt_root_path));

    // Load or Initialize serializable data

    std::ifstream f(fs::path(ckpt_root_path) / "data.json");
    if (!f.fail()) {
        cereal::JSONInputArchive archive(f);
        cereal::serialize(archive, *this);
    }

    for (auto &x : info.input_signals) {
        signal_trace.try_emplace(x);
    }
}
