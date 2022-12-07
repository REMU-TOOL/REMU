#ifndef _LOADER_H_
#define _LOADER_H_

#include "checkpoint.h"
#include "bitvector.h"
#include "yaml-cpp/yaml.h"

#include <map>
#include <stdexcept>

namespace Replay {

struct CircuitInfo
{
    struct Reg
    {
        BitVector data;
    };

    struct RegArray
    {
        BitVectorArray data;
        int start_offset;
    };

    std::map<std::string, Reg> regs;
    std::map<std::string, RegArray> regarrays;
    std::map<std::string, CircuitInfo*> cells;

    using PathType = std::vector<std::string>;

    CircuitInfo* cell(PathType::const_iterator begin, PathType::const_iterator end)
    {
        CircuitInfo* p = this;
        while (begin != end)
            p = p->cells.at(*begin++);

        return p;
    }

    CircuitInfo* cell(const PathType &path) { return cell(path.cbegin(), path.cend()); }

    Reg& reg(PathType::const_iterator begin, PathType::const_iterator end)
    {
        if (begin == end)
            throw std::runtime_error("empty path specified");

        return cell(begin, end - 1)->regs.at(end[-1]);
    }

    Reg& reg(const PathType &path) { return reg(path.cbegin(), path.cend()); }

    RegArray& regarray(PathType::const_iterator begin, PathType::const_iterator end)
    {
        if (begin == end)
            throw std::runtime_error("empty path specified");

        return cell(begin, end - 1)->regarrays.at(end[-1]);
    }

    RegArray& regarray(const PathType &path) { return regarray(path.cbegin(), path.cend()); }

    CircuitInfo* make_cell(PathType::const_iterator begin, PathType::const_iterator end)
    {
        CircuitInfo* p = this;
        while (begin != end) {
            if (p->cells.find(*begin) == p->cells.end()) {
                p->cells[*begin] = new CircuitInfo;
            }
            p = p->cells.at(*begin++);
        }
        return p;
    }

    CircuitInfo* make_cell(const PathType &path) { return make_cell(path.cbegin(), path.cend()); }

    Reg& make_reg(int width, PathType::const_iterator begin, PathType::const_iterator end)
    {
        if (begin == end)
            throw std::runtime_error("empty path specified");

        auto cell = make_cell(begin, end - 1);
        auto &name = end[-1];

        auto it = cell->regs.find(name);
        if (it != cell->regs.end()) {
            if (it->second.data.width() != width)
                throw std::runtime_error("reg of different dimension already exists");

            return it->second;
        }

        Reg data = {BitVector(width)};
        auto res = cell->regs.emplace(name, data);
        return res.first->second;
    }

    Reg& make_reg(int width, const PathType &path) { return make_reg(width, path.cbegin(), path.cend()); }

    RegArray& make_regarray(int width, int depth, int start_offset, PathType::const_iterator begin, PathType::const_iterator end)
    {
        if (begin == end)
            throw std::runtime_error("empty path specified");

        auto cell = make_cell(begin, end - 1);
        auto &name = end[-1];

        auto it = cell->regarrays.find(name);
        if (it != cell->regarrays.end()) {
            if (it->second.data.width() != width ||
                it->second.data.depth() != depth ||
                it->second.start_offset != start_offset)
                throw std::runtime_error("reg of different dimension already exists");

            return it->second;
        }

        RegArray data = {BitVectorArray(width, depth), start_offset};
        auto res = cell->regarrays.emplace(name, data);
        return res.first->second;
    }

    RegArray& make_regarray(int width, int depth, int start_offset, const PathType &path) { return make_regarray(width, depth, start_offset, path.cbegin(), path.cend()); }

    CircuitInfo() = default;
    CircuitInfo(const CircuitInfo &) = delete;
    CircuitInfo(CircuitInfo &&) = default;
    CircuitInfo& operator=(const CircuitInfo &) = delete;
    CircuitInfo& operator=(CircuitInfo &&) = default;

    CircuitInfo(const YAML::Node &config)
    {
        auto &ff_list = config["ff"];
        for (auto &ff : ff_list) {
            auto name = ff["name"].as<std::vector<std::string>>();
            int width = ff["wire_width"].as<int>();
            make_reg(width, name);
        }
        auto &ram_list = config["ram"];
        for (auto &ram : ram_list) {
            auto name = ram["name"].as<std::vector<std::string>>();
            int width = ram["width"].as<int>();
            int depth = ram["depth"].as<int>();
            int start_offset = ram["start_offset"].as<int>();
            make_regarray(width, depth, start_offset, name);
        }
    }

    ~CircuitInfo()
    {
        for (auto &it : cells)
            delete it.second;
    }
};

class CircuitLoader {
    const YAML::Node &config;
    CircuitInfo &circuit;

public:

    void load(Checkpoint &checkpoint);

    CircuitLoader(const YAML::Node &config, CircuitInfo &circuit) :
        config(config), circuit(circuit) {}
};

};

#endif // #ifndef _LOADER_H_
