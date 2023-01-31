#include "kernel/yosys.h"

#include "combdeps.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace REMU;

void CombDeps::setup()
{
    design_types.clear();
    design_types.setup_design(hier.design);
    primitive_types.clear();
    primitive_types.setup_internals();
    primitive_types.setup_stdcells();

    module_sigmap.clear();

    for (auto &path : hier.tree.topoSort(true)) {
        auto &node = hier.dag.nodes.at(path.data.dag_node);
        Module *module = hier.design->module(node.name);
        module_sigmap.insert({node.name, SigMap(module)});
        auto &sigmap = module_sigmap.at(node.name);

        for (Cell *cell : module->cells()) {
            if (primitive_types.cell_known(cell->type)) {
                // simply add deps from inputs to outputs
                pool<SigBit> inputs, outputs;
                for (auto &conn : cell->connections()) {
                    auto &target_pool = primitive_types.cell_input(cell->type, conn.first) ?
                        inputs : outputs;
                    for (auto b : conn.second) {
                        sigmap.apply(b);
                        if (b.is_wire())
                            target_pool.insert(b);
                    }
                }
                for (auto &i : inputs) {
                    auto &inode = signal_dag[SignalInfo(path.index, i)];
                    for (auto &o : outputs) {
                        auto &onode = signal_dag[SignalInfo(path.index, o)];
                        signal_dag.addEdge(std::make_pair(__empty(), __empty()), inode.index, onode.index);
                    }
                }
            }
            else if (design_types.cell_known(cell->type)) {
                auto &subpath = hier.tree.follow(path, cell->name);
                for (auto &conn : cell->connections()) {
                    for (auto b : conn.second) {
                        sigmap.apply(b);
                        if (!b.is_wire())
                            continue;
                        Module *submodule = hier.design->module(cell->type);
                        Wire *subwire = submodule->wire(conn.first);
                        SigBit s(subwire, b.offset);
                        module_sigmap.at(cell->type).apply(s);
                        if (!s.is_wire())
                            continue;
                        auto &bnode = signal_dag[SignalInfo(path.index, b)];
                        auto &snode = signal_dag[SignalInfo(subpath.index, s)];
                        if (subwire->port_input)
                            signal_dag.addEdge(std::make_pair(__empty(), __empty()), bnode.index, snode.index);
                        else
                            signal_dag.addEdge(std::make_pair(__empty(), __empty()), snode.index, bnode.index);
                    }
                }
            }
        }
    }

    SignalDAG::DFSWorker worker(&signal_dag);
    if (!worker.sort(true)) {
        log("Combinational logic loop found (backtrace):\n");
        auto &ns = worker.node_stack;
        auto nslen = ns.size();
        log_assert(nslen >= 2);
        size_t npos = nslen - 2;
        int last = ns.back();
        while (ns.at(npos) != last)
            npos--;
        while (npos < nslen) {
            log("  [W] ");
            auto &data = signal_dag.nodes.at(ns.at(npos)).data;
            for (auto name : hier.tree.nodes.at(data.path).data.hier)
                log("%s.", log_id(name));
            log("%s[%d]\n", log_id(data.bit.name), data.bit.offset);
            npos++;
        }
        log_error("Combinational logic loop is not allowed\n");
    }
}

PRIVATE_NAMESPACE_BEGIN

struct EmuTestCombDeps : public Pass {
    EmuTestCombDeps() : Pass("emu_test_comb_deps", "test comb deps functionality") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_test_comb_deps <hier> ... : <signal list>\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_TEST_COMB_DEPS pass.\n");

        Hierarchy hier(design);
        Module *module = design->module(hier.dag.rootNode().name);
        CombDeps deps(hier);

        std::vector<IdString> path;
        pool<CombDeps::SignalInfo> signals;

        size_t argidx;
        bool is_arg_signal = false;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            auto &s = args[argidx];

            if (s == ":") {
                is_arg_signal = true;
                continue;
            }

            if (s[0] != '\\' && s[0] != '$') {
                log("%s: illegal IdString\n", s.c_str());
                return;
            }

            IdString name(s);

            if (is_arg_signal) {
                Wire *wire = module->wire(name);
                if (!wire) {
                    log("%s: wire not found (in module %s)\n", name.c_str(), log_id(module));
                    return;
                }
                auto &node = hier.tree.follow(path);
                for (auto &b : SigSpec(wire))
                    signals.insert(CombDeps::SignalInfo(node.index, b));
            }
            else {
                path.push_back(name);
                Cell *inst = module->cell(name);
                if (!inst) {
                    log("%s: instance not found (in module %s)\n", name.c_str(), log_id(module));
                    return;
                }
                module = design->module(inst->type);
                log_assert(module);
            }
        }

        auto deps_enum = deps.enumerate(signals);

        while (!deps_enum.empty()) {
            auto &node = deps_enum.get();
            for (auto &s : hier.tree.nodes.at(node.data.path).data.hier)
                log("%s ", s.c_str());
            log(": ");
            log("%s[%d]\n", node.data.bit.name.c_str(), node.data.bit.offset);
            deps_enum.next();
        }
    }
} EmuTestCombDeps;

PRIVATE_NAMESPACE_END
