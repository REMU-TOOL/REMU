#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuTransformPass : public Pass {
	EmuTransformPass() : Pass("emu_transform", "transform design for emulation") { }
	void help() override
	{
		//   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
		log("\n");
		log("    emu_transform [options]\n");
		log("\n");
		log("This command runs an emulator transformation.\n");
		log("\n");
        log("    -cfg <file>\n");
        log("        write generated configuration to the specified file\n");
        log("    -ldr <file>\n");
        log("        write generated simulation loader to the specified file\n");
		log("    -top <module>\n");
		log("        use the specified module as top module\n");
		log("\n");
		log("    hierarchy -check (-top <top> | -auto-top)\n");
		log("    emu_keep_top\n");
		log("    proc\n");
		log("    flatten\n");
		log("    opt\n");
		log("    wreduce\n");
		log("    memory_share\n");
		log("    memory_collect\n");
		log("    opt -fast\n");
		log("    check\n");
		log("    opt_expr -keepdc\n");
		log("    emu_lint\n");
		log("    emu_opt_ram\n");
		log("    opt_clean\n");
		log("    emu_instrument [-cfg <file>] [-ldr <file>]\n");
		log("    emu_remove_keep\n");
		log("    check\n");
		log("    opt\n");
		log("    emu_extract_mem\n");
		log("    opt\n");
		log("\n");
	}
	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		std::string cfg_file, ldr_file, top_module;

		log_header(design, "Executing PROC pass (convert processes to netlists).\n");
		log_push();

        size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++)
		{
            if (args[argidx] == "-cfg" && argidx+1 < args.size()) {
                cfg_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-ldr" && argidx+1 < args.size()) {
                ldr_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-top" && argidx+1 < args.size()) {
                top_module = args[++argidx];
                continue;
            }
            break;
		}
		extra_args(args, argidx, design);

        if (top_module.empty())
            Pass::call(design, "hierarchy -check -auto-top");
        else
            Pass::call(design, "hierarchy -check -top " + top_module);
        Pass::call(design, "emu_keep_top");
        Pass::call(design, "proc");
        Pass::call(design, "flatten");
        Pass::call(design, "opt");
        Pass::call(design, "wreduce");
        Pass::call(design, "memory_share");
        Pass::call(design, "memory_collect");
        Pass::call(design, "opt -fast");
        Pass::call(design, "check");

        Pass::call(design, "emu_lint");
        Pass::call(design, "emu_opt_ram");
        Pass::call(design, "opt_clean");
        std::string emu_instrument = "emu_instrument";
        if (!cfg_file.empty())
            emu_instrument += " -cfg " + cfg_file;
        if (!ldr_file.empty())
            emu_instrument += " -ldr " + ldr_file;
        Pass::call(design, emu_instrument);
        Pass::call(design, "emu_remove_keep");
        Pass::call(design, "check");

        Pass::call(design, "opt");
        Pass::call(design, "emu_extract_mem");
        Pass::call(design, "opt");

		log_pop();
	}

} EmuTransformPass;

PRIVATE_NAMESPACE_END
