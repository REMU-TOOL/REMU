#include "emulib.h"
#include "kernel/yosys.h"

USING_YOSYS_NAMESPACE

using namespace Emu;

static void add_source_folder(std::vector<std::string> &sources, const std::string &path)
{
    if (!check_file_exists(path, true))
        log_error("EmuLibInfo: cannot locate path %s\n", path.c_str());

    auto results = glob_filename(path + "*.v");
    sources.insert(sources.end(), results.begin(), results.end());
}

EmuLibInfo::EmuLibInfo()
{
    std::string emulib_dirname = proc_self_dirname() + "../share/remu/emulib/";

    if (!check_file_exists(emulib_dirname, true))
        log_error("EmuLibInfo: cannot locate emulib path\n");

    verilog_include_path = emulib_dirname + "/include";
    if (!check_file_exists(verilog_include_path, true))
        log_error("EmuLibInfo: cannot locate emulib include path\n");

    add_source_folder(model_sources, emulib_dirname + "common/");
    add_source_folder(model_sources, emulib_dirname + "model/");
    add_source_folder(model_sources, emulib_dirname + "fpga/");
    add_source_folder(platform_sources, emulib_dirname + "common/");
    add_source_folder(platform_sources, emulib_dirname + "platform/");
}
