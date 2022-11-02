#include "kernel/yosys.h"
#include "kernel/utils.h"

#include "hier.h"

#include <queue>

USING_YOSYS_NAMESPACE

using namespace Emu;

void Hierarchy::setup(Design *design)
{
    dag.clear();
    tree.clear();

    // setup DAG nodes

    dag.nodes.reserve(design->modules_.size());
    size_t dag_edge_count = 0;
    for (Module *module : design->modules()) {
        dag.addNode(std::make_pair(module->name, DAGNode()));
        for (Cell *cell : module->cells())
            if (cell->type[0] == '\\')
                dag_edge_count++;
    }

    Module *top = design->top_module();
    if (!top)
        log_error("No top module found\n");

    auto &dag_root = dag.findNode(top->name);
    dag.root = dag_root.index;

    // setup DAG edges

    dag.edges.reserve(dag_edge_count);
    for (Module *module : design->modules())
        for (Cell *cell : module->cells())
            if (cell->type[0] == '\\') {
                Module *from_module = cell->module;
                Module *to_module = design->module(cell->type);
                if (!to_module)
                    log_error("Unresolvable module name %s\n", to_module->name.c_str());

                auto &from_node = dag.findNode(from_module->name);
                auto &to_node = dag.findNode(to_module->name);

                auto edge_name = std::make_pair(from_node.index, cell->name);
                dag.addEdge(std::make_pair(edge_name, DAGEdge()),
                    from_node.index,
                    to_node.index);
            }

    decltype(dag)::DFSWorker sort_worker(&dag);
    if (!sort_worker.sort(true))
        log_error("circular module instantation found");

    // setup tree

    std::queue<int> workqueue;

    size_t tree_node_count = 0; 

    workqueue.push(dag.root);
    while (!workqueue.empty()) {
        int dag_nid = workqueue.front();
        workqueue.pop();
        tree_node_count++;
        auto &dag_node = dag.nodes.at(dag_nid);
        for (auto &dag_edge : dag_node.outEdges())
            workqueue.push(dag_edge.to);
    }

    tree.nodes.reserve(tree_node_count);
    tree.edges.reserve(tree_node_count);

    TreeNode tree_root_data;
    tree_root_data.dag_node = dag.root;

    tree.root = tree.addNode(std::make_pair(dag_root.name, tree_root_data)).index;

    workqueue.push(tree.root);
    while (!workqueue.empty()) {
        int tree_nid = workqueue.front();
        workqueue.pop();
        auto &tree_node = tree.nodes.at(tree_nid);
        auto &dag_node = dag.nodes.at(tree_node.data.dag_node);
        auto node_data = tree_node.data;
        for (auto &dag_edge : dag_node.outEdges()) {
            // Note: tree_node may be invalidated by addNode()
            TreeNode subnode_data;
            subnode_data.hier = node_data.hier;
            subnode_data.hier.push_back(dag_edge.name.second);
            subnode_data.dag_node = dag_edge.to;
            auto &tree_subnode = tree.addNode(std::make_pair(dag_edge.toNode().name, subnode_data));
            auto tree_edge_name = std::make_pair(tree_nid, dag_edge.name.second);
            tree.addEdge(std::make_pair(tree_edge_name, TreeEdge()),
                tree_nid,
                tree_subnode.index);
            workqueue.push(tree_subnode.index);
        }
    }
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestHierarchy : public Pass {
    EmuTestHierarchy() : Pass("emu_test_hierarchy", "test hierarchy functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_HIERARCHY pass.\n");

        Hierarchy hier(design);

        for (auto &node : hier.dag.nodes) {
            log("node %d:\n", node.index);
            log("  name: %s\n", node.name.c_str());
            log("  in:");
            for (auto edge : node.inEdges())
                log(" %d(%s)", edge.index, edge.name.second.c_str());
            log("\n");
            log("  out:");
            for (auto edge : node.outEdges())
                log(" %d(%s)", edge.index, edge.name.second.c_str());
            log("\n");
        }

        for (auto &edge : hier.dag.edges) {
            auto &f = edge.fromNode();
            auto &t = edge.toNode();
            log("edge %d(%s): %d(%s) -> %d(%s) next=%d\n", edge.index,
                edge.name.second.c_str(),
                f.index, f.name.c_str(),
                t.index, t.name.c_str(),
                edge.next);
        }

        log("sorted:\n");
        for (auto &node : hier.dag.topoSort(true)) {
            log("  %s\n", node.name.c_str());
        }
        log("\n");

        int path_count = 0;
        for (auto path : hier.tree.topoSort(true)) {
            log("path %d:", path_count++);
            for (auto name : path.data.hier)
                log(" %s", name.c_str());
            log("\n");
        }
    }
} EmuTestHierarchy;

PRIVATE_NAMESPACE_END
