#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "emuutil.h"

using namespace EmuUtil;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuKeepTopPass : public Pass {
    EmuKeepTopPass() : Pass("emu_keep_top", "add keep attribute to cells & wires in top module") { }

    void execute(vector<string> args, Design* design) override {
        (void)args;
        log_header(design, "Executing EMU_KEEP_TOP pass.\n");

        Module *top = design->top_module();
        if (!top)
            log_error("No top module found");
        
        log("Processing module %s...\n", log_id(top));

        for (auto cell : top->selected_cells())
            cell->set_bool_attribute(ID::keep);

        for (auto wire : top->selected_wires())
            wire->set_bool_attribute(ID::keep);
    }
} EmuKeepTopPass;

PRIVATE_NAMESPACE_END
