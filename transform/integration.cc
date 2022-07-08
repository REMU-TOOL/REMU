#include "kernel/yosys.h"

#include "emu.h"
#include "attr.h"
#include "transform.h"

#include <queue>

using namespace Emu;

USING_YOSYS_NAMESPACE

void DesignIntegration::execute(EmulationRewriter &rewriter) {
    Design *design = rewriter.design().design();

    log_header(design, "Executing DesignIntegration.\n");
    log_push();

    std::string share_dirname = proc_share_dirname() + "../recheck/";
    std::vector<std::string> read_verilog_argv = {
        "read_verilog",
        "-I",
        share_dirname + "emulib/include",
        share_dirname + "emulib/platform/*.v"
    };

    Pass::call(design, read_verilog_argv);

    Pass::call(design, "hierarchy");
    Pass::call(design, "proc");
    Pass::call(design, "opt");

    log_pop();
}
