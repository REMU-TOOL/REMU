#ifndef _LOADER_H_
#define _LOADER_H_

#include "emu_info.h"
#include "checkpoint.h"
#include "bitvector.h"

#include <string>
#include <vector>
#include <map>
#include <stdexcept>

namespace REMU {

class CircuitState
{
    decltype(SysInfo::scan_ff) scan_ff;
    decltype(SysInfo::scan_ram) scan_ram;

public:

    struct WireState
    {
        BitVector data;
    };

    struct RAMState
    {
        BitVectorArray data;
        bool dissolved;
    };

    std::map<std::vector<std::string>, WireState> wire;
    std::map<std::vector<std::string>, RAMState> ram;

    void load(Checkpoint &checkpoint);
    void save(Checkpoint &checkpoint);

    CircuitState(const SysInfo &sysinfo);
};

struct CircuitPath : public std::vector<std::string>
{
    using std::vector<std::string>::vector;

    CircuitPath(const std::vector<std::string> &path) : vector(path) {}
    CircuitPath(std::vector<std::string> &&path) : vector(std::move(path)) {}

    CircuitPath operator/(const CircuitPath &other) const
    {
        CircuitPath res(*this);
        res.insert(res.end(), other.begin(), other.end());
        return res;
    }

    CircuitPath operator/(const std::string &s) const
    {
        CircuitPath res(*this);
        res.push_back(s);
        return res;
    }
};

};

#endif // #ifndef _LOADER_H_
