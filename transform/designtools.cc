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

const pool<std::string> VerilogIdEscape::keywords = {
    "accept_on", "alias", "always", "always_comb", "always_ff", "always_latch", "and",
    "assert", "assign", "assume", "automatic", "before", "begin", "bind", "bins", "binsof",
    "bit", "break", "buf", "bufif0", "bufif1", "byte", "case", "casex", "casez", "cell",
    "chandle", "checker", "class", "clocking", "cmos", "config", "const", "constraint",
    "context", "continue", "cover", "covergroup", "coverpoint", "cross", "deassign",
    "default", "defparam", "design", "disable", "dist", "do", "edge", "else", "end",
    "endcase", "endchecker", "endclass", "endclocking", "endconfig", "endfunction", "endgenerate",
    "endgroup", "endinterface", "endmodule", "endpackage", "endprimitive", "endprogram",
    "endproperty", "endspecify", "endsequence", "endtable", "endtask", "enum", "event",
    "eventually", "expect", "export", "extends", "extern", "final", "first_match", "for",
    "force", "foreach", "forever", "fork", "forkjoin", "function", "generate", "genvar",
    "global", "highz0", "highz1", "if", "iff", "ifnone", "ignore_bins", "illegal_bins",
    "implements", "implies", "import", "incdir", "include", "initial", "inout", "input",
    "inside", "instance", "int", "integer", "interconnect", "interface", "intersect",
    "join", "join_any", "join_none", "large", "let", "liblist", "library", "local", "localparam",
    "logic", "longint", "macromodule", "matches", "medium", "modport", "module", "nand",
    "negedge", "nettype", "new", "nexttime", "nmos", "nor", "noshowcancelled", "not",
    "notif0", "notif1", "null", "or", "output", "package", "packed", "parameter", "pmos",
    "posedge", "primitive", "priority", "program", "property", "protected", "pull0",
    "pull1", "pulldown", "pullup", "pulsestyle_ondetect", "pulsestyle_onevent", "pure",
    "rand", "randc", "randcase", "randsequence", "rcmos", "real", "realtime", "ref",
    "reg", "reject_on", "release", "repeat", "restrict", "return", "rnmos", "rpmos",
    "rtran", "rtranif0", "rtranif1", "s_always", "s_eventually", "s_nexttime", "s_until",
    "s_until_with", "scalared", "sequence", "shortint", "shortreal", "showcancelled",
    "signed", "small", "soft", "solve", "specify", "specparam", "static", "string", "strong",
    "strong0", "strong1", "struct", "super", "supply0", "supply1", "sync_accept_on",
    "sync_reject_on", "table", "tagged", "task", "this", "throughout", "time", "timeprecision",
    "timeunit", "tran", "tranif0", "tranif1", "tri", "tri0", "tri1", "triand", "trior",
    "trireg", "type", "typedef", "union", "unique", "unique0", "unsigned", "until", "until_with",
    "untyped", "use", "uwire", "var", "vectored", "virtual", "void", "wait", "wait_order",
    "wand", "weak", "weak0", "weak1", "while", "wildcard", "wire", "with", "within",
    "wor", "xnor", "xor"
};

class VerilogIdEscape Emu::VerilogIdEscape;

std::string VerilogIdEscape::operator()(const std::string &name) {
    if (name.empty())
        goto escape;

    if (!isalpha(name[0]) && name[0] != '_')
        goto escape;

    for (size_t i = 1; i < name.size(); i++) {
        char c = name[i];
        if (!isalnum(c) && c != '_' && c != '$')
            goto escape;
    }

    if (keywords.count(name) != 0)
        goto escape;

    return name;

escape:
    return "\\" + name + " ";
}

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

    for (auto module : design->modules()) {
        children_dict[module].clear();
        for (auto cell : module->cells()) {
            Module *tpl = design->module(cell->type);
            if (tpl) {
                if (inst_dict.count(tpl) != 0)
                    log_error("Module %s is not unique. Run uniquify first.\n", log_id(tpl));
                inst_dict[tpl] = cell;
                children_dict[module].insert(tpl);
            }
        }
    }

    inst_dict[top_] = nullptr;

    // Add wire connections to sigmap

    for (Module *module : design->modules()) {
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
                            hier_name_of(tpl_wire).c_str()
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

    for (Module *module : design->modules()) {
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
            log("Multiple drivers found for signal %s:\n", hier_name_of(it.first).c_str());
            for (auto &driver : it.second) {
                log("    %s.%s[%d]\n",
                    hier_name_of(driver.cell).c_str(),
                    log_id(driver.port),
                    driver.offset);
            }
            log_error("Multiple drivers are not allowed\n");
        }
    }
}

DesignInfo::Path DesignInfo::path_of(Module *mod, Module *scope) const {
    Path res, stack;

    while (true) {
        stack.push_back(mod);
        Cell *cell = inst_dict.at(mod);
        if (!cell) break;
        mod = cell->module;
        if (mod == scope) break;
    }

    res.insert(res.end(), stack.rbegin(), stack.rend());

    return res;
}

std::vector<std::string> DesignInfo::scope_of(Module *mod) const {
    std::vector<std::string> res, stack;

    while (mod != top_) {
        Cell *cell = inst_dict.at(mod);
        stack.push_back(name_of(cell->name));
        mod = cell->module;
    }

    stack.push_back(name_of(top_->name));

    for (auto it = stack.rbegin(); it != stack.rend(); ++it)
        res.push_back(*it);

    return res;
}

pool<SigBit> DesignInfo::find_dependencies(pool<SigBit> target, pool<SigBit> candidate) {
    bool find_all = candidate.empty();
    pool<SigBit> result;
    pool<SigBit> visited;
    dict<SigBit, SigBit> candidate_map; // mapped -> original
    std::queue<SigBit> worklist;

    for (SigBit &bit : candidate)
        candidate_map[sigmap(bit)] = bit;

    for (SigBit &bit : target)
        if (bit.is_wire())
            worklist.push(bit);

    while (!worklist.empty()) {
        SigBit bit = sigmap(worklist.front());
        worklist.pop();

        if (visited.count(bit) > 0)
            continue;

        visited.insert(bit);

        if (find_all) {
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
            log("Drivers of %s:\n", info.hier_name_of(bit).c_str());
            auto portbits = info.get_drivers(bit);
            for (auto &portbit : portbits) {
                log("  - %s.%s[%d]\n", info.hier_name_of(portbit.cell).c_str(), log_id(portbit.port), portbit.offset);
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
            log("Consumers of %s:\n", info.hier_name_of(bit).c_str());
            auto portbits = info.get_consumers(bit);
            for (auto &portbit : portbits) {
                log("  - %s.%s[%d]\n", info.hier_name_of(portbit.cell).c_str(), log_id(portbit.port), portbit.offset);
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
            log("Dependencies of %s:\n", info.hier_name_of(bit).c_str());
            auto deps = info.find_dependencies({bit}, {});
            for (auto &dep : deps) {
                log("  - %s\n", info.hier_name_of(dep).c_str());
            }
            log("------------------------------\n");
        }
    }
} DtFindDependencyPass;

PRIVATE_NAMESPACE_END
