#ifndef _EMU_HIER_H_
#define _EMU_HIER_H_

#include "kernel/yosys.h"

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

    struct DAGNode {};
    struct DAGEdge {};

    using DAGNodeName = Yosys::IdString;
    using DAGEdgeName = std::pair<int, Yosys::IdString>; // (node id, edge name)

    using DAGNodeMap = MapType<DAGNodeName>;
    using DAGEdgeMap = MapType<DAGEdgeName>;

    struct TreeNode
    {
        std::vector<Yosys::IdString> hier;
        int dag_node;
    };

    struct TreeEdge {};

    using TreeNodeName = Yosys::IdString;
    using TreeEdgeName = std::pair<int, Yosys::IdString>; // (node id, edge name)

    using TreeNodeMap = void;
    using TreeEdgeMap = MapType<TreeEdgeName>;

    HierDAG<DAGNode, DAGEdge, DAGNodeName, DAGEdgeName, DAGNodeMap, DAGEdgeMap> dag;
    HierDAG<TreeNode, TreeEdge, TreeNodeName, TreeEdgeName, TreeNodeMap, TreeEdgeMap> tree;

    void setup(Yosys::Design *design);

    Hierarchy(Yosys::Design *design)
    {
        setup(design);
    }
};

}

#endif //#ifndef _EMU_HIER_H_
