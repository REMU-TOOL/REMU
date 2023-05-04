#include "emulib.h"

#include <filesystem>

using namespace REMU;

static void add_source_folder(std::vector<std::string> &sources, const std::string &path)
{
    for (auto &entry : std::filesystem::recursive_directory_iterator(path)) {
        if (entry.is_regular_file()) {
            sources.push_back(entry.path());
        }
    }
}

EmuLibInfo::EmuLibInfo(std::string emulib_path)
{
    verilog_include_path = emulib_path + "/include";
    add_source_folder(model_sources, emulib_path + "common/");
    add_source_folder(model_sources, emulib_path + "model/");
    add_source_folder(model_sources, emulib_path + "fpga/");
    add_source_folder(system_sources, emulib_path + "common/");
    add_source_folder(system_sources, emulib_path + "system/");
}
