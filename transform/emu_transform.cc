#include "kernel/yosys.h"

#include "database.h"
#include "ram.h"
#include "port.h"
#include "model.h"
#include "clock.h"
#include "scanchain.h"
#include "fame.h"
#include "system.h"
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
        log("    -out <file>\n");
        log("        write generated emulator system design to the specified file\n");
        log("    -sysinfo <file>\n");
        log("        write system info to the specified file\n");
        log("    -loader <file>\n");
        log("        write verilog loader definition to the specified file\n");
        log("    -ckpt <path>\n");
        log("        write initial checkpoint\n");
        log("    -nosystem\n");
        log("        skip system transformation\n");
        log("    -rewrite_arst\n");
        log("        rewrite async resets to sync resets\n");
        log("\n");
    }

    std::string top, elab_file, out_file, sysinfo_file, loader_file, ckpt_path;
    bool raw_plat = false;
    bool rewrite_arst = false;

    EmuLibInfo emulib;

    void integrate(Design *design) {
        log_header(design, "Executing design integration.\n");
        log_push();

        std::vector<std::string> load_model_cmd({"read_verilog", "-noautowire", "-I", emulib.verilog_include_path});
        load_model_cmd.insert(load_model_cmd.end(), emulib.model_sources.begin(), emulib.model_sources.end());

        Pass::call(design, load_model_cmd);

        Pass::call(design, {"hierarchy", "-top", top, "-simcheck"});

        Pass::call(design, "emu_preserve_top");
        Pass::call(design, "proc");
        Pass::call(design, "emu_fast_opt");

        Pass::call(design, "memory_collect");
        Pass::call(design, "memory_share -nosat -nowiden");
        Pass::call(design, "emu_opt_shallow_memory");
        Pass::call(design, "opt -full */t:$mem* %m");

        if (rewrite_arst) {
            Pass::call(design, "emu_rewrite_async_reset_ff");
        }

        Pass::call(design, "emu_check");

        if (!elab_file.empty()) {
            // Produce an elaborated design without FPGA model implementations for replay use
            Pass::call(design, "design -push-copy");
            Pass::call(design, "blackbox A:__emu_model_imp");
            Pass::call(design, "hierarchy");
            Pass::call(design, "check"); // check pass should be called before blackboxes are removed
            Pass::call(design, "emu_restore_param_cells -mod-attr __emu_model_imp");
            Pass::call(design, "delete =A:blackbox");
            Pass::call(design, "emu_package -top EMU_TOP");
            Pass::call(design, "write_verilog -noattr " + elab_file);
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
            if (args[argidx] == "-out" && argidx+1 < args.size()) {
                out_file = args[++argidx];
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
            if (args[argidx] == "-ckpt" && argidx+1 < args.size()) {
                ckpt_path = args[++argidx];
                continue;
            }
            if (args[argidx] == "-nosystem") {
                raw_plat = true;
                continue;
            }
            if (args[argidx] == "-rewrite_arst") {
                rewrite_arst = true;
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        if (top.empty())
            log_error("No top module specified\n");

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
            log_header(design, "Executing system transformation.\n");
            log_push();
            SystemTransform worker(design, database, emulib);
            worker.run();
            log_pop();
        }

        final_cleanup(design);

        log_header(design, "Writing output files.\n");

        if (!out_file.empty())
            Pass::call(design, {"write_verilog", "-noattr", out_file});

        if (!sysinfo_file.empty())
            database.write_sysinfo(sysinfo_file);

        if (!loader_file.empty())
            database.write_loader(loader_file);

        if (!ckpt_path.empty())
            database.write_checkpoint(ckpt_path);

        log_pop();
    }
} EmuTransformPass;

PRIVATE_NAMESPACE_END
