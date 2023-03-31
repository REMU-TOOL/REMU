#include "kernel/yosys.h"
#include "kernel/ff.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuRestoreParamCells : public Pass {
    EmuRestoreParamCells() : Pass("emu_rewrite_async_reset_ff", "rewrite FF async resets to sync resets") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_rewrite_async_reset_ff [selection]\n");
        log("\n");
        log("This command rewrites FF asynchronous resets to synchronous resets. This is a\n");
        log("workaround to support designs using asynchronous resets. Be aware that this\n");
        log("transformation does not always generate a working design.\n");
        log("\n");
    }

    std::string top_name;

    void execute(vector<string> /*args*/, Design* design) override
    {
        log_header(design, "Executing EMU_REWRITE_ASYNC_RESET_FF pass.\n");
        log_push();

        for (auto module : design->selected_modules()) {
            log("Processing module %s\n", module->name.c_str());
            for (auto cell : module->selected_cells()) {
                if (RTLIL::builtin_ff_cell_types().count(cell->type) == 0)
                    continue;

                FfData ff(nullptr, cell);
                if (ff.has_arst) {
                    log_warning("Rewriting async-reset FF %s\n", module->name.c_str());
                    ff.has_arst = false;
                    ff.has_srst = true;
                    ff.sig_srst = ff.sig_arst;
                    ff.pol_srst = ff.pol_arst;
                    ff.val_srst = ff.val_arst;
                    ff.emit();
                }
            }
        }

        log_pop();
    }

} EmuRestoreParamCells;

PRIVATE_NAMESPACE_END
