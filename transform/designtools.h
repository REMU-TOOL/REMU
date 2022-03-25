#ifndef _DESIGNTOOLS_H_
#define _DESIGNTOOLS_H_

#include "kernel/yosys.h"
#include "kernel/modtools.h"

namespace Emu {

USING_YOSYS_NAMESPACE

struct DesignWalker {
    Design *design;
    ModWalker modwalker;

    dict<Module *, pool<Cell *>> inst_map; // module to its instantiations

    void add(Module *module) {
        for (auto cell : module->cells()) {
            Module *tpl = design->module(cell->type);
            if (tpl)
                inst_map[tpl].insert(cell);
        }
    }

    pool<Cell *> instances_of(Module *module) {
        if (module && inst_map.count(module))
            return inst_map.at(module);
        return {};
    }

    DesignWalker(Design *design) : design(design), modwalker(design) {
        for (auto module : design->modules())
            add(module);
    }
};

// Hierarchy representation for a uniquified design

struct DesignHierarchy {

    using Path = std::vector<Module *>;

    Module *top;
    dict<Module *, Cell *> inst_map;

    void set(Design *design) {
        top = design->top_module();
        inst_map.clear();

        for (auto module : design->modules()) {
            if (!module->get_bool_attribute(ID::unique) &&
                !module->get_bool_attribute(ID::top))
                log_error("Module %s is not unique. Run uniquify first.\n", log_id(module));

            for (auto cell : module->cells()) {
                Module *tpl = design->module(cell->type);
                if (tpl)
                    inst_map[tpl] = cell;
            }
        }
    }

    Cell *instance_of(Module *module) const {
        return inst_map.at(module);
    }

    Path path_of(Module *mod) const {
        Path res, stack;

        for (; mod != top; mod = inst_map.at(mod)->module)
            stack.push_back(mod);

        stack.push_back(top);

        for (auto it = stack.rbegin(); it != stack.rend(); ++it)
            res.push_back(*it);

        return res;
    }

    Path path_of(Cell *cell) const {
        return path_of(cell->module);
    }

    Path path_of(Wire *wire) const {
        return path_of(wire->module);
    }

    std::vector<std::string> scope_of(Module *mod) const {
        std::vector<std::string> res, stack;

        while (mod != top) {
            Cell *cell = inst_map.at(mod);
            stack.push_back(cell->name[0] == '\\' ? cell->name.substr(1) : cell->name.str());
            mod = cell->module;
        }

        stack.push_back(top->name[0] == '\\' ? top->name.substr(1) : top->name.str());

        for (auto it = stack.rbegin(); it != stack.rend(); ++it)
            res.push_back(*it);

        return res;
    }

    void connect(Wire *lhs, Wire *rhs) {
        log_assert(GetSize(lhs) == GetSize(rhs));

        // Fast path for connection in the same module
        if (lhs->module == rhs->module) {
            lhs->module->connect(lhs, rhs);
            return;
        }

        int size = GetSize(lhs);

        Path lpath = path_of(lhs);
        Path rpath = path_of(rhs);

        // Find parent in common
        Module *parent = top;
        for (auto lit = lpath.begin(), rit = rpath.begin();
            lit != lpath.end() && rit != rpath.end() && *lit == *rit;
            ++lit, ++rit)
            parent = *lit;

        // Process wire name
        IdString conn_name;
        if (rhs->name[0] == '\\')
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
            Cell *inst = inst_map.at(scope);
            scope = inst->module;
            Wire *outer = scope->addWire(scope->uniquify(conn_name), size);
            inst->setPort(lwire->name, outer);
            lwire = outer;
        }

        // Expose RHS
        Wire *rwire = rhs;
        for (Module *scope = rpath.back(); scope != parent; ) {
            rwire->port_output = true; scope->fixup_ports();
            Cell *inst = inst_map.at(scope);
            scope = inst->module;
            Wire *outer = scope->addWire(scope->uniquify(conn_name), size);
            inst->setPort(rwire->name, outer);
            rwire = outer;
        }

        // Connect topmost wires
        parent->connect(lwire, rwire);
    }

    DesignHierarchy(Design *design) {
        set(design);
    }
};

} // namespace Emu

#endif // #ifndef _DESIGNTOOLS_H_
