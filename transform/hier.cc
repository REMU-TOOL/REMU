#include "kernel/yosys.h"
#include "kernel/utils.h"

#include "hier.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

void Hierarchy::addModule(Module *module) {
    log_assert(node_map.count(module->name) == 0);

    auto &node = addNode(module->name);

    node_map[module->name] = node.index;
}

void Hierarchy::addInst(Cell *inst) {
    Module *from_module = inst->module;
    Module *to_module = from_module->design->module(inst->type);
    if (!to_module)
        log_error("Unresolvable module name %s\n", to_module->name.c_str());

    addEdge(inst->name,
        node_map.at(from_module->name),
        node_map.at(to_module->name));
}

Hierarchy::Hierarchy(Design *design) {
    nodes.reserve(design->modules_.size());
    int edge_count = 0;
    for (Module *module : design->modules()) {
        addModule(module);
        for (Cell *cell : module->cells())
            if (cell->type[0] == '\\')
                edge_count++;
    }

    edges.reserve(edge_count);
    for (Module *module : design->modules())
        for (Cell *cell : module->cells())
            if (cell->type[0] == '\\')
                addInst(cell);

    Module *top = design->top_module();
    if (!top)
        log_error("No top module found\n");

    root = node_map.at(top->name);
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestHierarchy : public Pass {
    EmuTestHierarchy() : Pass("emu_test_hierarchy", "test hierarchy functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_HIERARCHY pass.\n");

        Hierarchy hier(design);

        for (auto &node : hier.nodes) {
            log("node %d:\n", node.index);
            log("  name: %s\n", node.data.c_str());
            log("  in:");
            for (auto edge : node.inEdges())
                log(" %d(%s)", edge.index, edge.data.c_str());
            log("\n");
            log("  out:");
            for (auto edge : node.outEdges())
                log(" %d(%s)", edge.index, edge.data.c_str());
            log("\n");
        }

        for (auto &edge : hier.edges) {
            auto &f = edge.fromNode();
            auto &t = edge.toNode();
            log("edge %d(%s): %d(%s) -> %d(%s) next=%d\n", edge.index,
                edge.data.c_str(),
                f.index, f.data.c_str(),
                t.index, t.data.c_str(),
                edge.next);
        }

        int path_count = 0;
        for (auto path : hier.traverse()) {
            log("path %d:", path_count++);
            for (auto e : path)
                log(" %s", e->data.c_str());
            log("\n");
        }

        log("sorted:\n");
        for (auto &node : hier.topoSort(true)) {
            log("  %s\n", node.data.c_str());
        }
        log("\n");
    }
} EmuTestHierarchy;

PRIVATE_NAMESPACE_END
