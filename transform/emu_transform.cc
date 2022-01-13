#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuTransformPass : public ScriptPass {
	EmuTransformPass() : ScriptPass("emu_transform", "transform design for emulation") { }
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
		log("The following commands will be executed:\n");
		help_script();
		log("\n");
	}

	std::string cfg_file, ldr_file, top_module;

	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		log_header(design, "Executing EMU_TRANSFORM pass.\n");
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

		run_script(design);

		log_pop();
	}

	void script() override {

        run("emu_database reset");

		std::string share_dirname = proc_share_dirname();

        run("read_verilog -I " + share_dirname + "emulib/include " +
			share_dirname + "emulib/model/*.v");

		if (help_mode) {
			run("hierarchy -check {-top <top> | -auto-top}");
		}
		else {
			if (top_module.empty())
				run("hierarchy -check -auto-top");
			else
				run("hierarchy -check -top " + top_module);
		}

        run("emu_preproc_attr");
        run("proc");
        run("opt");
        run("wreduce");
        run("memory_share");
        run("memory_collect");
        run("opt -fast");
        run("check");

        run("emu_check");
        run("emu_opt_ram");
        run("opt_clean");
        run("emu_rewrite_clock");
        run("emu_process_lib");
		run("emu_prop_attr -a emu_no_scanchain");
        run("emu_instrument");
        run("emu_package");

		if (help_mode)
			run("emu_database write_config -file <file> (if -cfg)");
		else if (!cfg_file.empty())
            run("emu_database write_config -file " + cfg_file);

		if (help_mode)
			run("emu_database write_loader -file <file> (if -ldr)");
        if (!ldr_file.empty())
            run("emu_database write_loader -file " + ldr_file);

        run("emu_postproc_attr");
        run("check");

        run("opt");
        run("submod");
        run("opt");

	}

} EmuTransformPass;

PRIVATE_NAMESPACE_END
