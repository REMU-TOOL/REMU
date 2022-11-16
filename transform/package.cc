#include "kernel/yosys.h"

#include "package.h"
#include "utils.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

inline IdString package_name(IdString name)
{
    return "\\EMU_SYSTEM_" + pretty_name(name, false);
}

void PackageWorker::run()
{
    for (auto &node : hier.dag.topoSort(true)) {
        Module *module = node.data.module;
        IdString new_name;
        if (node.index == hier.dag.root)
            new_name = "\\EMU_SYSTEM";
        else
            new_name = package_name(module->name);

        for (Cell *cell : module->cells().to_vector()) {
            if (hier.celltypes.cell_known(cell->type)) {
                cell->type = package_name(cell->type);
            }
        }

        log("Renaming module %s to %s\n", log_id(module), log_id(new_name));

        hier.design->rename(module, new_name);
    }
}
