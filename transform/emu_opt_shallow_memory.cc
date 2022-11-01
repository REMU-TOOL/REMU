#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuOptShallowMemoryPass : public Pass {
    EmuOptShallowMemoryPass() : Pass("emu_opt_shallow_memory", "map shallow memories to flip-flops") { }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_OPT_SHALLOW_MEMORY pass.\n");

        int threshold = 2;
        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++) {
            // TODO: threshold
            break;
        }
        extra_args(args, argidx, design);

        RTLIL::Selection selection(false);

        for (auto mod : design->modules()) {
            for (auto &mem : Mem::get_all_memories(mod)) {
                if (mem.size <= threshold) {
                    if (mem.packed)
                        selection.select(mod, mem.cell);
                    else
                        selection.select(mod, mem.mem);
                }
            }
        }

        log_push();
        Pass::call_on_selection(design, selection, "memory_map");
        log_pop();
    }

} EmuOptShallowMemoryPass;

PRIVATE_NAMESPACE_END
