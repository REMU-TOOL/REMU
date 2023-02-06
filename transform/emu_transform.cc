#include "kernel/yosys.h"

#include "database.h"
#include "ram.h"
#include "port.h"
#include "model.h"
#include "clock.h"
#include "scanchain.h"
#include "fame.h"
#include "platform.h"
#include "emulib.h"

using namespace REMU;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct EmuTransformPass : public Pass {
    EmuTransformPass() : Pass("emu_transform", "perform emulation transformation") { }

    void help() override
    {
        //   |---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|---v---|
        log("\n");
        log("    emu_transform [options]\n");
        log("\n");
        log("This command transforms the design to an FPGA emulator.\n");
        log("\n");
        log("    -top <module>\n");
        log("        specify top module name\n");
        log("    -elab <file>\n");
        log("        write elaborated verilog design to the specified file\n");
        log("    -sysinfo <file>\n");
        log("        write system info to the specified file\n");
        log("    -loader <file>\n");
        log("        write verilog loader definition to the specified file\n");
        log("    -no_plat\n");
        log("        skip platform transformation\n");
        log("\n");
    }

    std::string top, elab_file, sysinfo_file, loader_file;
    bool raw_plat = false;

    EmuLibInfo emulib;

    void integrate(Design *design) {
        log_header(design, "Executing design integration.\n");
        log_push();

        std::vector<std::string> load_model_cmd({"read_verilog", "-noautowire", "-I", emulib.verilog_include_path});
        load_model_cmd.insert(load_model_cmd.end(), emulib.model_sources.begin(), emulib.model_sources.end());

        Pass::call(design, load_model_cmd);

        if (top.empty())
            Pass::call(design, "hierarchy -auto-top");
        else
            Pass::call(design, "hierarchy -top " + top);

        Pass::call(design, "emu_preserve_top");
        Pass::call(design, "proc");
        Pass::call(design, "emu_fast_opt");

        Pass::call(design, "memory_collect");
        Pass::call(design, "memory_share -nosat -nowiden");
        //Pass::call(design, "emu_opt_shallow_memory");
        Pass::call(design, "opt_clean");

        Pass::call(design, "emu_check");

        if (!elab_file.empty()) {
            // Produce an elaborated design without FPGA model implementations for replay use
            Pass::call(design, "design -push-copy");
            Pass::call(design, "blackbox A:__emu_model_imp");
            Pass::call(design, "hierarchy");
            Pass::call(design, "check"); // check pass should be called before blackboxes are removed
            Pass::call(design, "emu_restore_param_cells -mod-attr __emu_model_imp");
            Pass::call(design, "delete =A:blackbox");
            Pass::call(design, "write_rtlil /tmp/foo.txt");
            Pass::call(design, "emu_package -top EMU_ELAB");
            Pass::call(design, "write_verilog " + elab_file);
            Pass::call(design, "design -pop");
        }

        log_pop();
    }

    void final_cleanup(Design *design) {
        log_header(design, "Executing final cleanup.\n");
        log_push();

        Pass::call(design, "select */t:$mem* %m");
        Pass::call(design, "opt -full");
        Pass::call(design, "submod");
        Pass::call(design, "select -clear");
        Pass::call(design, "opt_clean");
        Pass::call(design, "emu_remove_keep");

        log_pop();
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_TRANSFORM pass.\n");
        log_push();

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-top" && argidx+1 < args.size()) {
                top = args[++argidx];
                continue;
            }
            if (args[argidx] == "-elab" && argidx+1 < args.size()) {
                elab_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-sysinfo" && argidx+1 < args.size()) {
                sysinfo_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-loader" && argidx+1 < args.size()) {
                loader_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-no_plat") {
                raw_plat = true;
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        integrate(design);

        EmulationDatabase database;

        {
            log_header(design, "Executing RAM transformation.\n");
            log_push();
            RAMTransform worker(design, database);
            worker.run();
            log_pop();
        }

        {
            log_header(design, "Executing port transformation.\n");
            log_push();
            PortTransform worker(design, database);
            worker.run();
            log_pop();
        }

        {
            log_header(design, "Executing model analysis.\n");
            log_push();
            ModelAnalyzer worker(design, database);
            worker.run();
            log_pop();
        }

        {
            log_header(design, "Executing clock tree transformation.\n");
            log_push();
            ClockTreeRewriter worker(design, database);
            worker.run();
            log_pop();
        }

        {
            log_header(design, "Executing scanchain insertion.\n");
            log_push();
            ScanchainWorker worker(design, database);
            worker.run();
            log_pop();
        }

        // Remove unused modules generated by ScanchainWorker
        Pass::call(design, "hierarchy");

        {
            log_header(design, "Executing FAME transformation.\n");
            log_push();
            FAMETransform worker(design, database);
            worker.run();
            log_pop();
        }

        Pass::call(design, "emu_package -top EMU_SYSTEM");

        if (!raw_plat) {
            log_header(design, "Executing platform transformation.\n");
            log_push();
            PlatformTransform worker(design, database, emulib);
            worker.run();
            log_pop();
        }

        final_cleanup(design);

        log_header(design, "Writing output files.\n");

        if (!sysinfo_file.empty())
            database.write_sysinfo(sysinfo_file);

        if (!loader_file.empty())
            database.write_loader(loader_file);

        log_pop();
    }
} EmuTransformPass;

PRIVATE_NAMESPACE_END
