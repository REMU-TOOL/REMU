#include "kernel/yosys.h"

#include "combdeps.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

void CombDeps::setup()
{
    primitive_types.clear();
    primitive_types.setup_internals();
    primitive_types.setup_stdcells();

    module_sigmap.clear();

    signal_dag = SignalDAG();

    for (auto &path : hier.traverse()) {
        HashablePath hp(path);
        auto &node = path.empty() ? hier.rootNode() : path.back()->toNode();
        Module *module = design->module(node.data);
        module_sigmap.insert({node.data, SigMap(module)});
        auto &sigmap = module_sigmap.at(node.data);

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
                    auto &inode = signal_dag[SignalInfo(hp, i)];
                    for (auto &o : outputs) {
                        auto &onode = signal_dag[SignalInfo(hp, o)];
                        signal_dag.addEdge(inode, onode);
                    }
                }
            }
            else if (cell->type[0] == '\\') {
                HashablePath hpsub = hp.push(cell->name);
                for (auto &conn : cell->connections()) {
                    for (auto b : conn.second) {
                        sigmap.apply(b);
                        if (!b.is_wire())
                            continue;
                        Module *submodule = design->module(cell->type);
                        Wire *subwire = submodule->wire(conn.first);
                        SigBit s(subwire, b.offset);
                        module_sigmap.at(cell->type).apply(s);
                        if (!s.is_wire())
                            continue;
                        auto &bnode = signal_dag[SignalInfo(hp, b)];
                        auto &snode = signal_dag[SignalInfo(hpsub, s)];
                        if (subwire->port_input)
                            signal_dag.addEdge(bnode, snode);
                        else
                            signal_dag.addEdge(snode, bnode);
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
        size_t npos = nslen - 1;
        int last = -1;
        while (true) {
            int n = ns.at(npos);
            if (last < 0)
                last = n;
            else if (last == n)
                break;
            npos--;
        }
        while (npos < nslen) {
            log("  [W] ");
            auto &data = signal_dag.nodes.at(ns.at(npos)).data;
            for (auto name : data.path.path)
                log("%s.", log_id(name));
            log("%s[%d]\n", log_id(data.bit.name), data.bit.offset);
            npos++;
        }
        log_error("Combinational logic loop detected\n");
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
        Module *module = design->module(hier.rootNode().data);
        CombDeps deps(design, hier);

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
                for (auto &b : SigSpec(wire))
                    signals.insert(CombDeps::SignalInfo(path, b));
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
            for (auto &s : node.data.path.path)
                log("%s ", s.c_str());
            log(": ");
            log("%s[%d]\n", node.data.bit.name.c_str(), node.data.bit.offset);
            deps_enum.next();
        }
    }
} EmuTestCombDeps;

PRIVATE_NAMESPACE_END
