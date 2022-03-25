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
        log("    -sc_yaml <file>\n");
        log("        write generated scan chain configuration in yaml to the specified file\n");
        log("    -loader <file>\n");
        log("        write verilog loader definition to the specified file\n");
		log("    -top <module>\n");
		log("        use the specified module as top module\n");
		log("\n");
		log("The following commands will be executed:\n");
		help_script();
		log("\n");
	}

	std::string sc_yaml, loader, top_module;

	void execute(std::vector<std::string> args, RTLIL::Design *design) override
	{
		log_header(design, "Executing EMU_TRANSFORM pass.\n");
		log_push();

        size_t argidx;
		for (argidx = 1; argidx < args.size(); argidx++)
		{
            if (args[argidx] == "-sc_yaml" && argidx+1 < args.size()) {
                sc_yaml = args[++argidx];
                continue;
            }
            if (args[argidx] == "-loader" && argidx+1 < args.size()) {
                loader = args[++argidx];
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

        run("emu_preserve_top");
		run("prep");
        run("memory_share");

        run("emu_check");
        run("emu_opt_ram");
        run("opt_clean");

		run("uniquify");
		run("hierarchy");

        run("emu_handle_directive");

		if (help_mode) {
			run("emu_instrument [-yaml <sc_yaml>] [-loader <loader>]");
		}
		else {
			std::string cmd = "emu_instrument";
			if (!sc_yaml.empty())
            	cmd += " -yaml " + sc_yaml;
			if (!loader.empty())
            	cmd += " -loader " + loader;
			run(cmd);
		}

        run("emu_package");

        run("emu_remove_keep");
        run("check");

        run("opt");
        run("submod");
        run("opt");

	}

} EmuTransformPass;

PRIVATE_NAMESPACE_END
