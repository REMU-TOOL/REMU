#include "kernel/yosys.h"

#include "emu.h"
#include "transform.h"
#include "interface.h"

using namespace Emu;

USING_YOSYS_NAMESPACE
PRIVATE_NAMESPACE_BEGIN

struct TransformHelper {

    EmulationDatabase &database;
    EmulationRewriter &rewriter;

    void run(Transform &&transform) {
        transform.execute(database, rewriter);
        rewriter.update_design();
    }

    TransformHelper(EmulationDatabase &database, EmulationRewriter &rewriter)
        : database(database), rewriter(rewriter) {}

};

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
        log("    -ff_width <width>\n");
        log("        specify the width of FF scan chain (default=64)\n");
        log("    -ram_width <width>\n");
        log("        specify the width of RAM scan chain (default=64)\n");
        log("    -elab <file>\n");
        log("        write elaborated verilog design to the specified file\n");
        log("    -init <file>\n");
        log("        write initial scan chain data to the specified file\n");
        log("    -yaml <file>\n");
        log("        write generated yaml configuration to the specified file\n");
        log("    -loader <file>\n");
        log("        write verilog loader definition to the specified file\n");
        log("    -no_plat\n");
        log("        export raw wires in platform transformation\n");
        log("\n");
    }

    std::string top, elab_file, init_file, yaml_file, loader_file;
    int ff_width = 64, ram_width = 64;
    bool raw_plat = false;

    void elaborate(Design *design) {
        log_header(design, "Executing design elaboration.\n");
        log_push();

        std::string share_dirname = proc_share_dirname() + "../recheck/";

        Pass::call(design, {
            "read_verilog",
            share_dirname + "emulib/stub/*.v"
        });

        if (top.empty())
            Pass::call(design, "hierarchy -auto-top");
        else
            Pass::call(design, "hierarchy -top " + top);

        Pass::call(design, "emu_preserve_top");
        Pass::call(design, "proc");
        Pass::call(design, "opt");
        Pass::call(design, "check");

        if (!elab_file.empty())
            Pass::call(design, "write_verilog " + elab_file);

        log_pop();
    }

    void pre_integrate(Design *design) {
        log_header(design, "Executing pre-transform integration.\n");
        log_push();

        std::string share_dirname = proc_share_dirname() + "../recheck/";

        Pass::call(design, {
            "read_verilog",
            "-I",
            share_dirname + "emulib/include",
            share_dirname + "emulib/common/*.v",
            share_dirname + "emulib/fpga/*.v"
        });

        Pass::call(design, "hierarchy -purge_lib");
        Pass::call(design, "proc");
        Pass::call(design, "opt_clean");
        Pass::call(design, "memory_collect");
        Pass::call(design, "memory_share -nowiden");

        Pass::call(design, "emu_check");
        Pass::call(design, "uniquify");
        Pass::call(design, "hierarchy");

        log_pop();
    }

    void post_integrate(Design *design) {
        log_header(design, "Executing post-transform integration.\n");
        log_push();

        std::string share_dirname = proc_share_dirname() + "../recheck/";

        Pass::call(design, {
            "read_verilog",
            "-I",
            share_dirname + "emulib/include",
            share_dirname + "emulib/platform/*.v"
        });

        Pass::call(design, "hierarchy");
        Pass::call(design, "proc");
        Pass::call(design, "opt");

        log_pop();
    }

    void final_cleanup(Design *design) {
        log_header(design, "Executing final cleanup.\n");
        log_push();

        Pass::call(design, "submod");
        Pass::call(design, "uniquify");
        Pass::call(design, "hierarchy");
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
            if (args[argidx] == "-ff_width" && argidx+1 < args.size()) {
                ff_width = std::stoi(args[++argidx]);
                continue;
            }
            if (args[argidx] == "-ram_width" && argidx+1 < args.size()) {
                ram_width = std::stoi(args[++argidx]);
                continue;
            }
            if (args[argidx] == "-elab" && argidx+1 < args.size()) {
                elab_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-init" && argidx+1 < args.size()) {
                init_file = args[++argidx];
                continue;
            }
            if (args[argidx] == "-yaml" && argidx+1 < args.size()) {
                yaml_file = args[++argidx];
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

        elaborate(design);

        pre_integrate(design);

        EmulationDatabase database;

        EmulationRewriter rewriter(design);
        rewriter.setup_wires(ff_width, ram_width);

        TransformHelper helper(database, rewriter);

        helper.run(IdentifySyncReadMem());
        helper.run(PortTransform());
        helper.run(TargetTransform());
        helper.run(ClockTransform());
        helper.run(InsertScanchain());
        if (!raw_plat)
            helper.run(PlatformTransform());

        post_integrate(design);

        ExportInterfaceWorker intf_worker(database, design);
        intf_worker.run();

        final_cleanup(design);

        log_header(design, "Writing output files.\n");

        if (!init_file.empty())
            database.write_init(init_file);

        if (!yaml_file.empty())
            database.write_yaml(yaml_file);

        if (!loader_file.empty())
            database.write_loader(loader_file);

        log_pop();
    }
} EmuTransformPass;

PRIVATE_NAMESPACE_END
