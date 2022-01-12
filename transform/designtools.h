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


} // namespace Emu

#endif // #ifndef _DESIGNTOOLS_H_
