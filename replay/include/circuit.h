#ifndef _LOADER_H_
#define _LOADER_H_

#include "checkpoint.h"
#include "circuit_info.h"
#include "bitvector.h"
#include "yaml-cpp/yaml.h"

#include <map>

namespace Replay {

class CircuitDataScope
{
    std::map<int, BitVector> &ff_data_ref;
    std::map<int, BitVectorArray> &mem_data_ref;

public:

    CircuitInfo::Scope &scope;

    BitVector &ff(int id) { return ff_data_ref.at(id); }
    const BitVector &ff(int id) const { return ff_data_ref.at(id); }
    BitVector &ff(const std::vector<std::string> &path) { return ff(scope.get(path)->id); }
    const BitVector &ff(const std::vector<std::string> &path) const { return ff(scope.get(path)->id); }

    BitVectorArray &mem(int id) { return mem_data_ref.at(id); }
    const BitVectorArray &mem(int id) const { return mem_data_ref.at(id); }
    BitVectorArray &mem(const std::vector<std::string> &path) { return mem(scope.get(path)->id); }
    const BitVectorArray &mem(const std::vector<std::string> &path) const { return mem(scope.get(path)->id); }

    CircuitDataScope subscope(const std::vector<std::string> &path) const
    {
        auto &node = dynamic_cast<CircuitInfo::Scope&>(*scope.get(path));
        return CircuitDataScope(ff_data_ref, mem_data_ref, node);
    }

protected:

    CircuitDataScope(
        std::map<int, BitVector> &ff_data,
        std::map<int, BitVectorArray> &mem_data,
        CircuitInfo::Scope &scope
    ) : ff_data_ref(ff_data), mem_data_ref(mem_data), scope(scope) {}

};

class CircuitData : public CircuitDataScope
{
    std::map<int, BitVector> ff_data;
    std::map<int, BitVectorArray> mem_data;
    CircuitInfo::Scope root;

public:

    void init();

    CircuitData() : CircuitDataScope(ff_data, mem_data, root) {}

    CircuitData(const YAML::Node &config) : CircuitData()
    {
        root = CircuitInfo::Scope(config["circuit"]);
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
