#ifndef _EMU_TRANSFORM_HIER_H_
#define _EMU_TRANSFORM_HIER_H_

#include "kernel/yosys.h"
#include "kernel/celltypes.h"

#include "dag.h"

namespace Emu {

struct Hierarchy
{
    template<
        typename NT,
        typename ET,
        typename NKT,
        typename EKT,
        typename NMT = void,
        typename EMT = void
    >
    struct HierDAG : public DAG<NT, ET, NKT, EKT, NMT, EMT>
    {
        using BaseType = DAG<NT, ET, NKT, EKT, NMT, EMT>;
        using Node = typename BaseType::Node;
        using Edge = typename BaseType::Edge;

        int root = -1;

        Node& rootNode()
        {
            log_assert(root >= 0);
            return BaseType::nodes.at(root);
        }

        Node& follow(Node& from, Yosys::IdString name)
        {
            auto edge_name = std::make_pair(from.index, name);
            auto &edge = BaseType::findEdge(edge_name);
            return edge.toNode();
        }

        Node& follow(Node& from, const std::vector<Yosys::IdString> &path)
        {
            Node *p = &from;
            for (auto name : path) {
                auto edge_name = std::make_pair(p->index, name);
                auto &edge = BaseType::findEdge(edge_name);
                p = &edge.toNode();
            }
            return *p;
        }

        Node& follow(Yosys::IdString name)
        {
            return follow(rootNode(), name);
        }

        Node& follow(const std::vector<Yosys::IdString> &path)
        {
            return follow(rootNode(), path);
        }
    };

    template<typename T>
    using MapType = Yosys::dict<T, int>;

    Yosys::Design *design;
    Yosys::CellTypes celltypes;
    Yosys::IdString top;

    struct DAGNode
    {
        Yosys::Module *module;
        DAGNode(Yosys::Module *module) : module(module) {}
    };

    struct DAGEdge
    {
        Yosys::Cell *inst;
        DAGEdge(Yosys::Cell *inst) : inst(inst) {}
    };

    using DAGNodeName = Yosys::IdString;
    using DAGEdgeName = std::pair<int, Yosys::IdString>; // (node id, edge name)

    using DAGNodeMap = MapType<DAGNodeName>;
    using DAGEdgeMap = MapType<DAGEdgeName>;

    HierDAG<DAGNode, DAGEdge, DAGNodeName, DAGEdgeName, DAGNodeMap, DAGEdgeMap> dag;

    struct TreeNode
    {
        decltype(dag) *dag_p;
        int dag_node;
        Yosys::Module *module;
        std::vector<Yosys::IdString> hier;

        decltype(dag)::Node &toDAGNode()
        {
            return dag_p->nodes.at(dag_node);
        }

        TreeNode(decltype(dag) *dag_p, decltype(dag)::Node &dag_node) : dag_p(dag_p), dag_node(dag_node.index), module(dag_node.data.module) {}
    };

    struct TreeEdge {};

    using TreeNodeName = Yosys::IdString;
    using TreeEdgeName = std::pair<int, Yosys::IdString>; // (node id, edge name)

    using TreeNodeMap = void;
    using TreeEdgeMap = MapType<TreeEdgeName>;

    HierDAG<TreeNode, TreeEdge, TreeNodeName, TreeEdgeName, TreeNodeMap, TreeEdgeMap> tree;

    Hierarchy(Yosys::Design *design);
};

}

#endif //#ifndef _EMU_TRANSFORM_HIER_H_
