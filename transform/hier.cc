#include "hier.h"
#include "kernel/yosys.h"
#include "kernel/utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu::Hier;

void Hierarchy::addModule(Module *module) {
    log_assert(node_map.count(module->name) == 0);

    auto it = nodes.emplace(nodes.end(), this);
    it->name    = module->name;
    it->index   = it - nodes.begin();

    node_map[module->name] = it->index;
}

void Hierarchy::addInst(Cell *inst) {
    Module *from_module = inst->module;
    Module *to_module = from_module->design->module(inst->type);
    if (!to_module)
        log_error("Unresolvable module name %s\n", to_module->name.c_str());

    auto it = edges.emplace(edges.end(), this);
    it->name    = inst->name;
    it->from    = node_map.at(from_module->name);
    it->to      = node_map.at(to_module->name);
    it->index   = it - edges.begin();
    it->next    = -1;

    auto &out_edges = nodes.at(it->from).out;
    if (!out_edges.empty())
        edges.at(out_edges.back()).next = it->index;
    out_edges.push_back(it->index);

    nodes.at(it->to).in.push_back(it->index);
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

        for (auto node : hier.nodes) {
            log("node %d:\n", node.index);
            log("  name: %s\n", node.name.c_str());
            log("  in:");
            for (auto edge : node.inEdges())
                log(" %d(%s)", edge.index, edge.name.c_str());
            log("\n");
            log("  out:");
            for (auto edge : node.outEdges())
                log(" %d(%s)", edge.index, edge.name.c_str());
            log("\n");
        }

        for (auto edge : hier.edges) {
            auto &f = edge.fromNode();
            auto &t = edge.toNode();
            log("edge %d(%s): %d(%s) -> %d(%s) next=%d\n", edge.index,
                edge.name.c_str(),
                f.index, f.name.c_str(),
                t.index, t.name.c_str(),
                edge.next);
        }

        int path_count = 0;
        for (auto path : hier.traverse()) {
            log("path %d:", path_count++);
            for (auto e : path)
                log(" %s", e->name.c_str());
            log("\n");
        }
    }
} EmuTestHierarchy;

PRIVATE_NAMESPACE_END
