#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "emu.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

void obj_error(const char *msg, Module *module, IdString id, std::string src) {
    log("=== ERROR Traceback ===\n");
    for (auto &s : split_tokens(src, "|"))
        log("Object declared at %s\n", s.c_str());
    log_error("%s: %s.%s\n", msg, log_id(module), log_id(id));
}

void mem_error(const char *msg, Module *module, Mem &mem) {
    obj_error(msg, module, mem.memid, mem.get_src_attribute());
}

void ff_error(const char *msg, Module *module, Cell *cell) {
    SigSpec q = cell->getPort(ID::Q);
    if (q.is_wire()) {
        Wire *wire = q.chunks()[0].wire;
        obj_error(msg, module, wire->name, wire->get_src_attribute());
    }
    log_error("%s: %s.%s\n", msg, log_id(module), log_id(cell));
}

void emu_check(Module *module) {

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
            ff_error("Asynchronous logic not supported", module, cell);

        if (!ff.pol_clk)
            ff_error("Negedge clock polarity not supported", module, cell);
    }

    for (auto &mem : mem_cells) {
        for (auto &rd : mem.rd_ports) {
            // TODO: check for arst
            if (rd.clk_enable) {
                if (!rd.clk_polarity)
                    mem_error("Negedge clock polarity not supported in mem", module, mem);
            }
        }
        for (auto &wr : mem.wr_ports) {
            if (!wr.clk_enable)
                mem_error("Mem with asynchronous write port not supported", module, mem);
            if (!wr.clk_polarity)
                mem_error("Negedge clock polarity not supported in mem", module, mem);
        }
    }
}

struct EmuCheckPass : public Pass {
    EmuCheckPass() : Pass("emu_check", "do design check for an emulation transformation") { }

    void execute(vector<string> args, Design* design) override {
        (void)args;
        log_header(design, "Executing EMU_CHECK pass.\n");

        auto modules = design->selected_modules();
        for (auto module : modules) {
            log("Checking module %s...\n", log_id(module));
            emu_check(module);
        }
    }
} EmuLintPass;

PRIVATE_NAMESPACE_END
