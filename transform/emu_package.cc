#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuRestoreParamCells : public Pass {
    EmuRestoreParamCells() : Pass("emu_package", "package the design by renaming modules") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_package [options]\n");
        log("\n");
        log("This command renames all modules with the specified name to package the design.\n");
        log("\n");
        log("    -top <module>\n");
        log("        specify a new top module name\n");
        log("\n");
    }

    std::string top_name;

    IdString packed_name(IdString orig_name)
    {
        return top_name + "_" + (orig_name[0] == '\\' ? orig_name.substr(1) : orig_name.str());
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_PACKAGE pass.\n");
        log_push();

		size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++) {
			if (args[argidx] == "-top") {
				top_name = args[++argidx];
				continue;
			}
			break;
		}
		extra_args(args, argidx, design);

        if (!design->full_selection())
            log_error("This command requires a fully selected design.");

        Module *top = design->top_module();

        if (!top)
            log_error("No top module found\n");

        if (top_name.empty())
            top_name = top->name.str();
        else
            top_name = "\\" + top_name;

        auto module_list = design->modules().to_vector();

        for (auto module : module_list)
            for (auto cell : module->cells())
                if (design->has(cell->type))
                    cell->type = packed_name(cell->type);

        for (auto module : module_list)
            if (module == top)
                design->rename(module, top_name);
            else
                design->rename(module, packed_name(module->name));

        log_pop();
    }

} EmuRestoreParamCells;

PRIVATE_NAMESPACE_END
