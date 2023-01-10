#include "kernel/yosys.h"
#include "kernel/ff.h"
#include "kernel/mem.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuRestoreParamCells : public Pass {
    EmuRestoreParamCells() : Pass("emu_fast_opt", "run opt pass on each module") { }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_FAST_OPT pass.\n");
        log_push();

        std::vector<std::string>
            opt_expr({"opt_expr"}),
            opt_merge({"opt_merge"}),
            opt_dff({"opt_dff"}),
            opt_clean({"opt_clean"});

		size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++) {
			if (args[argidx] == "-full") {
				opt_expr.push_back("-full");
				continue;
			}
			break;
		}
		extra_args(args, argidx, design);

        for (auto module : design->selected_modules()) {
            do {
                Pass::call_on_module(design, module, opt_expr);
                Pass::call_on_module(design, module, opt_merge);
                design->scratchpad_unset("opt.did_something");
                Pass::call_on_module(design, module, opt_dff);
            } while (design->scratchpad_get_bool("opt.did_something"));
        }
        Pass::call(design, opt_clean);

        log_pop();
    }

} EmuRestoreParamCells;

PRIVATE_NAMESPACE_END
