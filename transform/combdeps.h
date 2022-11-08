#ifndef _EMU_COMBDEPS_H_
#define _EMU_COMBDEPS_H_

#include "kernel/yosys.h"
#include "kernel/sigtools.h"
#include "kernel/celltypes.h"

#include "dag.h"
#include "hier.h"

#include <queue>

namespace Emu {

class CombDeps
{
public:

    struct WireBit
    {
        Yosys::IdString name;
        int offset;

        unsigned int hash() const
        {
            return Yosys::mkhash(name.hash(), Yosys::mkhash(offset));
        }

        bool operator==(const WireBit &other) const
        {
            return name == other.name && offset == other.offset;
        }

        WireBit() = default;
        WireBit(Yosys::IdString name, int offset) : name(name), offset(offset) {}
        WireBit(const Yosys::SigBit &bit) : name(bit.wire->name), offset(bit.offset) {}
    };

    struct SignalInfo
    {
        int path;
        WireBit bit;

        unsigned int hash() const
        {
            return Yosys::mkhash(Yosys::mkhash(path), bit.hash());
        }

        bool operator==(const SignalInfo &other) const
        {
            return path == other.path && bit == other.bit;
        }

        SignalInfo() = default;

        SignalInfo(int path, const WireBit &bit)
            : path(path), bit(bit) {}
    };

    struct __empty {};

    struct SignalDAG : DAG<SignalInfo, __empty, __empty, __empty>
    {
        std::vector<Yosys::dict<WireBit, int>> signal_dag_map; // path -> {bit -> node}

        bool has(const SignalInfo &info) const
        {
            return signal_dag_map.at(info.path).count(info.bit);
        }

        SignalDAG::Node& operator[](const SignalInfo &info)
        {
            auto &this_map = signal_dag_map[info.path];
            if (this_map.count(info.bit))
                return nodes.at(this_map.at(info.bit));

            auto &node = addNode(std::make_pair(__empty(), info));
            this_map[info.bit] = node.index;
            return node;
        }

        SignalDAG::Node& at(const SignalInfo &info)
        {
            return nodes.at(signal_dag_map.at(info.path).at(info.bit));
        }

        SignalDAG(Hierarchy &hier)
        {
            signal_dag_map.assign(hier.tree.nodes.size(), {});
        }
    };

    struct DepEnumerator
    {
        SignalDAG *dag;
        std::queue<int> worklist;
        Yosys::pool<int> visited;

        bool empty() const { return worklist.empty(); }

        SignalDAG::Node& get() const
        {
            return dag->nodes.at(worklist.front());
        }

        void next()
        {
            while (true) {
                int node_id = worklist.front();
                worklist.pop();

                if (visited.count(node_id))
                    continue;

                visited.insert(node_id);

                auto &node = dag->nodes.at(node_id);

                for (auto &e : node.outEdges())
                    worklist.push(e.to);

                break;
            }
        }

        DepEnumerator(SignalDAG *dag, const Yosys::pool<SignalInfo> &start) : dag(dag)
        {
            for (auto &info : start)
                if (dag->has(info))
                    worklist.push(dag->at(info).index);
        }
    };

private:

    Hierarchy &hier;

    Yosys::CellTypes design_types, primitive_types;
    Yosys::dict<Yosys::IdString, Yosys::SigMap> module_sigmap;

    SignalDAG signal_dag;

    void setup();

public:

    DepEnumerator enumerate(const Yosys::pool<SignalInfo> &start)
    {
        return DepEnumerator(&signal_dag, start);
    }

    CombDeps(Hierarchy &hier) : hier(hier), signal_dag(hier)
    {
        setup();
    }
};

};

#endif // #ifndef _EMU_COMBDEPS_H_
