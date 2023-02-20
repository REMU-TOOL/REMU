#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

#include "utils.h"

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
            pool<std::string> mem_names;
            for (auto &mem : Mem::get_all_memories(mod)) {
                if (mem.size > threshold)
                    continue;

                // ignore mems with inits
                if (mem.inits.size() > 0)
                    continue;

                // save mem info
                auto name = id2str(mem.memid);
                mem_names.insert(name);
                mod->set_intvec_attribute("\\dissolved_mem_" + name, {mem.width, mem.size, mem.start_offset});

                if (mem.packed)
                    selection.select(mod, mem.cell);
                else
                    selection.select(mod, mem.mem);
            }
            // save mem list
            mod->set_strpool_attribute("\\dissolved_mems", mem_names);
        }

        log_push();
        Pass::call_on_selection(design, selection, "memory_map");
        log_pop();
    }

} EmuOptShallowMemoryPass;

PRIVATE_NAMESPACE_END
