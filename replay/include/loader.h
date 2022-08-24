#ifndef _LOADER_H_
#define _LOADER_H_

#include "checkpoint.h"
#include "circuit_info.h"
#include "bitvector.h"
#include "yaml-cpp/yaml.h"

#include <map>

namespace Replay {

class CircuitData
{
    std::map<int, BitVector> ff_data;
    std::map<int, BitVectorArray> mem_data;
    CircuitInfo::Root root_;

public:

    void init();

    BitVector &ff(int id) { return ff_data.at(id); }
    const BitVector &ff(int id) const { return ff_data.at(id); }
    BitVectorArray &mem(int id) { return mem_data.at(id); }
    const BitVectorArray &mem(int id) const { return mem_data.at(id); }

    const CircuitInfo::Root &root() const { return root_; }

    CircuitData() {}

    CircuitData(const YAML::Node &config) : root_(config["circuit"])
    {
        init();
    }
};

class CircuitDataLoader {
    const YAML::Node &config;
    Checkpoint &checkpoint;
    CircuitData &circuit;

public:

    void load();

    CircuitDataLoader(const YAML::Node &config, Checkpoint &checkpoint, CircuitData &circuit) :
        config(config), checkpoint(checkpoint), circuit(circuit) {}
};

};

#endif // #ifndef _LOADER_H_
