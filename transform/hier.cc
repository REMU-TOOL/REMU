#include "hier.h"
#include "kernel/yosys.h"
#include "kernel/utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

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

    nodes.at(it->from).out.push_back(it->index);
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
    if (top) root = node_map.at(top->name);
}

Hierarchy::Range<Hierarchy::Node> Hierarchy::topoSort()
{
    TopoSort<int> topo;
    for (auto &node : nodes)
        topo.node(node.index);
    for (auto &edge : edges)
        topo.edge(edge.to, edge.from);
    if (!topo.sort())
        log_error("Circular module instantiation detected\n");
    return Hierarchy::RangeWithListStorage<Hierarchy::Node>(topo.sorted, &nodes);
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestHierarchy : public Pass {
    EmuTestHierarchy() : Pass("emu_test_hierarchy", "test hierarchy functionality") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing EMU_TEST_HIERARCHY pass.\n");

        Hierarchy hier(design);
        log("root: %d\n", hier.root);

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
            log("edge %d: %d(%s) -> %d(%s)\n", edge.index,
                f.index, f.name.c_str(),
                t.index, t.name.c_str());
        }
    }
} EmuTestHierarchy;

PRIVATE_NAMESPACE_END
