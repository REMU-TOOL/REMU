#ifndef _EMU_WALKER_CACHE_H_
#define _EMU_WALKER_CACHE_H_

#include "kernel/sigtools.h"
#include "kernel/modtools.h"

namespace Yosys {

class SigMapCache
{
    dict<Module*, SigMap> module_sigmap;

public:

    SigMap &operator[](Module *module) {
        if (!module_sigmap.count(module))
            module_sigmap.insert({module, SigMap(module)});
        return module_sigmap.at(module);
    }

    void clear() {
        module_sigmap.clear();
    }
};

class ModWalkerCache
{
    dict<Module*, ModWalker> module_walker;

public:

    ModWalker &operator[](Module *module) {
        if (!module_walker.count(module))
            module_walker.insert({module, ModWalker(module->design, module)});
        return module_walker.at(module);
    }

    void clear() {
        module_walker.clear();
    }
};

};

#endif // #ifndef _EMU_WALKER_CACHE_H_
