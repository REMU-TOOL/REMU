#ifndef _EMULIB_H_
#define _EMULIB_H_

#include <string>
#include <vector>

namespace Emu {

struct EmuLibInfo
{
    std::string verilog_include_path;
    std::vector<std::string> model_sources;
    std::vector<std::string> platform_sources;

    EmuLibInfo();
};

};

#endif // #ifndef _EMULIB_H_
