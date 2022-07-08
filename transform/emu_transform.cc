#include "kernel/yosys.h"

#include "emu.h"
#include "transform.h"

using namespace Emu;

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
        log("    -ff_width <width>\n");
        log("        specify the width of FF scan chain (default=64)\n");
        log("    -ram_width <width>\n");
        log("        specify the width of RAM scan chain (default=64)\n");
        log("    -init <file>\n");
        log("        write initial scan chain data to the specified file\n");
        log("    -yaml <file>\n");
        log("        write generated yaml configuration to the specified file\n");
        log("    -loader <file>\n");
        log("        write verilog loader definition to the specified file\n");
        log("    -raw-plat\n");
        log("        export raw wires in platform transformation\n");
        log("\n");
    }

    void execute(vector<string> args, Design* design) override {
        log_header(design, "Executing EMU_TRANSFORM pass.\n");
        log_push();

        std::string init_file, yaml_file, loader_file;
        int ff_width = 64, ram_width = 64;
        bool raw_plat = false;

        size_t argidx;
        for (argidx = 1; argidx < args.size(); argidx++)
        {
            if (args[argidx] == "-ff_width" && argidx+1 < args.size()) {
                ff_width = std::stoi(args[++argidx]);
                continue;
            }
            if (args[argidx] == "-ram_width" && argidx+1 < args.size()) {
                ram_width = std::stoi(args[++argidx]);
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
            if (args[argidx] == "-raw-plat") {
                raw_plat = true;
                continue;
            }
            break;
        }
        extra_args(args, argidx, design);

        EmulationRewriter rewriter(design);
        rewriter.setup_wires(ff_width, ram_width);

        TransformFlow flow(rewriter);

        flow.add(new IdentifySyncReadMem());
        flow.add(new PortTransform());
        flow.add(new TargetTransform());
        flow.add(new ClockTransform());
        flow.add(new InsertScanchain());
        flow.add(new PlatformTransform(raw_plat));
        flow.add(new DesignIntegration());
        flow.add(new InterfaceTransform());
        flow.run();

        log_pop();
    }
} EmuTransformPass;

PRIVATE_NAMESPACE_END
