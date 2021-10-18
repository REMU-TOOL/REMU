#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "emuutil.h"

using namespace EmuUtil;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

void lint_check(Module *module) {

    // RTLIL processes & memories are not accepted
    if (module->has_processes_warn() || module->has_memories_warn())
        log_error("RTLIL processes or memories detected");

    std::vector<Cell *> ff_cells;
    for (auto cell : module->selected_cells())
        if (RTLIL::builtin_ff_cell_types().count(cell->type))
            ff_cells.push_back(cell);

    std::vector<Mem> mem_cells = Mem::get_selected_memories(module);

    for (auto &cell : ff_cells) {
        FfData ff(nullptr, cell);

        if (!ff.has_clk || ff.has_arst || ff.has_sr)
            log_error("Cell type not supported: %s (%s.%s)\n", log_id(cell->type), log_id(module), log_id(cell));

        if (!ff.pol_clk)
            log_error("Negedge clock polarity not supported: %s (%s.%s)\n", log_id(cell->type), log_id(module), log_id(cell));
    }

    for (auto &mem : mem_cells) {
        for (auto &rd : mem.rd_ports) {
            // TODO: check for arst
            if (rd.clk_enable) {
                if (!rd.clk_polarity)
                    log_error("Negedge clock polarity not supported in mem %s.%s\n", log_id(module), log_id(mem.memid));
            }
        }
        for (auto &wr : mem.wr_ports) {
            if (!wr.clk_enable)
                log_error("Mem with asynchronous write port not supported (%s.%s)\n", log_id(module), log_id(mem.cell));
            if (!wr.clk_polarity)
                log_error("Negedge clock polarity not supported in mem %s.%s\n", log_id(module), log_id(mem.memid));
        }
    }
}

struct EmuLintPass : public Pass {
    EmuLintPass() : Pass("emu_lint", "do design lint check for an emulation transformation") { }

    void execute(vector<string> args, Design* design) override {
        (void)args;
        log_header(design, "Executing EMU_LINT pass.\n");

        auto modules = design->selected_modules();
        for (auto module : modules) {
            log("Checking module %s...\n", log_id(module));
            lint_check(module);
        }
    }
} EmuLintPass;

PRIVATE_NAMESPACE_END
