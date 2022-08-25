#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"
#include "kernel/sigtools.h"
#include "kernel/modtools.h"

#include "emu.h"
#include "designtools.h"

#include <queue>
#include <sstream>

using namespace Emu;

USING_YOSYS_NAMESPACE

void DesignInfo::setup(Design *design) {

    design_ = design;
    top_ = design->top_module();

    inst_dict.clear();
    children_dict.clear();

    ct.clear();
    ct.setup();
    sigmap.clear();
    signal_consumers.clear();
    signal_drivers.clear();

    comb_cell_types.clear();
    comb_cell_types.setup_internals();
    comb_cell_types.setup_stdcells();

    std::queue<Module *> worklist;

    worklist.push(top_);

    while (!worklist.empty()) {
        Module *module = worklist.front();
        worklist.pop();

        children_dict[module].clear();
        for (auto cell : module->cells()) {
            Module *tpl = design->module(cell->type);
            if (tpl) {
                worklist.push(tpl);
                if (inst_dict.count(tpl) != 0)
                    log_error("Module %s is not unique. Run uniquify first.\n", log_id(tpl));
                inst_dict[tpl] = cell;
                children_dict[module].insert(tpl);
            }
        }
    }

    inst_dict[top_] = nullptr;

    // Add wire connections to sigmap

    worklist.push(top_);

    while (!worklist.empty()) {
        Module *module = worklist.front();
        worklist.pop();

        for (Module *child : children_dict.at(module))
            worklist.push(child);

        for (auto &conn : module->connections())
            sigmap.add(conn.first, conn.second);

        for (Cell *cell : module->cells()) {
            if (design->has(cell->type)) {
                Module *tpl = design->module(cell->type);
                for (IdString port : tpl->ports) {
                    if (!cell->hasPort(port))
                        continue;

                    Wire *tpl_wire = tpl->wire(port);
                    SigSpec outer = cell->getPort(port);
                    SigSpec inner = SigSpec(tpl_wire);

                    if (tpl_wire->port_input && tpl_wire->port_output)
                        log_error("inout port %s is currently unsupported\n",
                            flat_name_of(tpl_wire).c_str()
                        );

                    if (tpl_wire->port_input) {
                        bool is_signed = outer.is_wire() && outer.as_wire()->is_signed;
                        outer.extend_u0(GetSize(inner), is_signed);
                        sigmap.add(inner, outer);
                    }
                    if (tpl_wire->port_output) {
                        bool is_signed = tpl_wire->is_signed;
                        inner.extend_u0(GetSize(outer), is_signed);
                        sigmap.add(outer, inner);
                    }
                }
            }
        }
    }

    // Add port connections to driver & consumer dict

    worklist.push(top_);

    while (!worklist.empty()) {
        Module *module = worklist.front();
        worklist.pop();

        for (Module *child : children_dict.at(module))
            worklist.push(child);

        for (Cell *cell : module->cells()) {
            if (ct.cell_known(cell->type)) {
                for (auto &conn : cell->connections()) {
                    bool is_input = ct.cell_input(cell->type, conn.first);
                    bool is_output = ct.cell_output(cell->type, conn.first);
                    for (int i = 0; i < GetSize(conn.second); i++) {
                        SigBit bit = sigmap(conn.second[i]);
                        if (is_input) {
                            signal_consumers[bit].insert({cell, conn.first, i});
                        }
                        if (is_output) {
                            signal_drivers[bit].insert({cell, conn.first, i});
                        }
                    }
                }
            }
        }
    }

    // Check multiple drivers

    for (auto &it : signal_drivers) {
        if (it.second.size() > 1) {
            log("Multiple drivers found for signal %s:\n", flat_name_of(it.first).c_str());
            for (auto &driver : it.second) {
                log("    %s.%s[%d]\n",
                    flat_name_of(driver.cell).c_str(),
                    log_id(driver.port),
                    driver.offset);
            }
            log_error("Multiple drivers are not allowed\n");
        }
    }
}

DesignInfo::Path DesignInfo::path_of(Module *mod, Module *scope) const {
    Path res, stack;

    while (mod != scope) {
        stack.push_back(mod);
        Cell *cell = inst_dict.at(mod);
        if (!cell) break;
        mod = cell->module;
    }

    res.insert(res.end(), stack.rbegin(), stack.rend());

    return res;
}

pool<SigBit> DesignInfo::find_dependencies(const pool<SigBit> &target, const pool<SigBit> *candidate) {
    pool<SigBit> result;
    pool<SigBit> visited;
    dict<SigBit, SigBit> candidate_map; // mapped -> original
    std::queue<SigBit> worklist;

    if (candidate != nullptr)
        for (auto &bit : *candidate)
            candidate_map[sigmap(bit)] = bit;

    for (auto &bit : target)
        if (bit.is_wire())
            worklist.push(bit);

    while (!worklist.empty()) {
        SigBit bit = sigmap(worklist.front());
        worklist.pop();

        if (visited.count(bit) > 0)
            continue;

        visited.insert(bit);

        if (candidate == nullptr) {
            result.insert(bit);
        }
        else if (candidate_map.count(bit) > 0) {
            result.insert(candidate_map.at(bit));
        }

        auto drivers = get_drivers(bit);
        for (auto &driver : drivers) {
            if (!comb_cell_types.cell_known(driver.cell->type))
                continue;

            for (auto &it : driver.cell->connections()) {
                if (!comb_cell_types.cell_input(driver.cell->type, it.first))
                    continue;

                for (SigBit b : it.second)
                    if (b.is_wire())
                        worklist.push(b);
            }
        }
    }

    return result;
}

void HierconnBuilder::connect(Wire *lhs, Wire *rhs, std::string suggest_name) {
    log_assert(GetSize(lhs) == GetSize(rhs));

    // Fast path for connection in the same module
    if (lhs->module == rhs->module) {
        lhs->module->connect(lhs, rhs);
        return;
    }

    int size = GetSize(lhs);

    auto lpath = designinfo.path_of(lhs);
    auto rpath = designinfo.path_of(rhs);

    // Find parent in common
    Module *parent = designinfo.top();
    for (auto lit = lpath.begin(), rit = rpath.begin();
        lit != lpath.end() && rit != rpath.end() && *lit == *rit;
        ++lit, ++rit)
        parent = *lit;

    // Process wire name
    IdString conn_name;
    if (!suggest_name.empty())
        conn_name = "\\" + suggest_name;
    else if (rhs->name[0] == '\\')
        conn_name = rhs->name.str() + "_hierconn";
    else if (lhs->name[0] == '\\')
        conn_name = lhs->name.str() + "_hierconn";
    else
        conn_name = "\\hierconn";

    if (lhs->name[0] != '\\')
        lhs->module->rename(lhs, lhs->module->uniquify(conn_name));

    if (rhs->name[0] != '\\')
        rhs->module->rename(rhs, rhs->module->uniquify(conn_name));

    // Expose LHS
    Wire *lwire = lhs;
    for (Module *scope = lpath.back(); scope != parent; ) {
        lwire->port_input = true; scope->fixup_ports();
        Cell *inst = designinfo.instance_of(scope);
        scope = inst->module;
        Wire *outer = scope->addWire(scope->uniquify(conn_name), size);
        inst->setPort(lwire->name, outer);
        lwire = outer;
    }

    // Expose RHS
    Wire *rwire = rhs;
    for (Module *scope = rpath.back(); scope != parent; ) {
        rwire->port_output = true; scope->fixup_ports();
        Cell *inst = designinfo.instance_of(scope);
        scope = inst->module;
        Wire *outer = scope->addWire(scope->uniquify(conn_name), size);
        inst->setPort(rwire->name, outer);
        rwire = outer;
    }

    // Make one of the wires anonymous
    if (lwire != lhs || rwire != rhs) {
        if (rwire != rhs)
            parent->rename(rwire, NEW_ID);
        else if (lwire != lhs)
            parent->rename(lwire, NEW_ID);
    }

    // Connect topmost wires
    parent->connect(lwire, rwire);
}

void HierconnBuilder::connect(const SigSpec &lhs, const SigSpec &rhs, std::string suggest_name)
{
    log_assert(GetSize(lhs) == GetSize(rhs));

    // Classify wire bits by module
    dict<std::pair<Module*, Module*>, SigSig> conn_dict;
    for (int i = 0; i < GetSize(lhs); i++) {
        auto &lb = lhs[i];
        auto &rb = rhs[i];
        if (!lb.is_wire()) continue;
        Module *lm = lb.wire->module;
        Module *rm = rb.is_wire() ? rb.wire->module : lm;
        auto &sigsig = conn_dict[std::make_pair(lm, rm)];
        sigsig.first.append(lb);
        sigsig.second.append(rb);
    }

    // Connect wire bits by module-to-module relationships
    for (auto &it : conn_dict) {
        Module *lm = it.first.first;
        Module *rm = it.first.second;
        auto &lhs = it.second.first;
        auto &rhs = it.second.second;

        if (GetSize(lhs) == 0)
            continue;

        if (lm == rm) {
            lm->connect(lhs, rhs);
            continue;
        }

        int size = GetSize(lhs);

        log_assert(lhs.chunks()[0].is_wire());
        log_assert(rhs.chunks()[0].is_wire());

        for (auto &c : lhs.chunks())
            log_assert(c.is_wire() && !c.wire->port_input);

        IdString lhs_name = lhs.chunks()[0].wire->name.str() + "_hierconn";
        IdString rhs_name = rhs.chunks()[0].wire->name.str() + "_hierconn";

        Wire *lhs_wire = lm->addWire(lm->uniquify(lhs_name), size);
        Wire *rhs_wire = rm->addWire(rm->uniquify(rhs_name), size);
        lm->connect(lhs, lhs_wire);
        rm->connect(rhs_wire, rhs);

        connect(lhs_wire, rhs_wire, suggest_name);
    }
}

PRIVATE_NAMESPACE_BEGIN

struct DtFindDriverPass : public Pass {
    DtFindDriverPass() : Pass("dt_find_driver", "find signal drivers (designtools test pass)") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing DT_FIND_DRIVER pass.\n");

        DesignInfo info(design);

        pool<SigBit> selection;
        for (Module *module : design->selected_modules())
            for (Wire *wire : module->selected_wires())
                for (SigBit &bit : SigSpec(wire))
                    selection.insert(bit);

        for (SigBit &bit : selection) {
            log("Drivers of %s:\n", info.flat_name_of(bit).c_str());
            auto portbits = info.get_drivers(bit);
            for (auto &portbit : portbits) {
                log("  - %s.%s[%d]\n", info.flat_name_of(portbit.cell).c_str(), log_id(portbit.port), portbit.offset);
            }
            log("------------------------------\n");
        }
    }
} DtFindDriverPass;

struct DtFindConsumerPass : public Pass {
    DtFindConsumerPass() : Pass("dt_find_consumer", "find signal consumers (designtools test pass)") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing DT_FIND_CONSUMER pass.\n");

        DesignInfo info(design);

        pool<SigBit> selection;
        for (Module *module : design->selected_modules())
            for (Wire *wire : module->selected_wires())
                for (SigBit &bit : SigSpec(wire))
                    selection.insert(bit);

        for (SigBit &bit : selection) {
            log("Consumers of %s:\n", info.flat_name_of(bit).c_str());
            auto portbits = info.get_consumers(bit);
            for (auto &portbit : portbits) {
                log("  - %s.%s[%d]\n", info.flat_name_of(portbit.cell).c_str(), log_id(portbit.port), portbit.offset);
            }
            log("------------------------------\n");
        }
    }
} DtFindConsumerPass;

struct DtFindDependencyPass : public Pass {
    DtFindDependencyPass() : Pass("dt_find_dependency", "find signal dependencies (designtools test pass)") { }

    void execute(vector<string> args, Design* design) override {
        extra_args(args, 1, design);
        log_header(design, "Executing DT_FIND_DEPENDENCY pass.\n");

        DesignInfo info(design);

        pool<SigBit> selection;
        for (Module *module : design->selected_modules())
            for (Wire *wire : module->selected_wires())
                for (SigBit &bit : SigSpec(wire))
                    selection.insert(bit);

        for (SigBit &bit : selection) {
            log("Dependencies of %s:\n", info.flat_name_of(bit).c_str());
            auto deps = info.find_dependencies({bit});
            for (auto &dep : deps) {
                log("  - %s\n", info.flat_name_of(dep).c_str());
            }
            log("------------------------------\n");
        }
    }
} DtFindDependencyPass;

PRIVATE_NAMESPACE_END
