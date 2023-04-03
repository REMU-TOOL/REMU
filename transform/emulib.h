#ifndef _EMULIB_H_
#define _EMULIB_H_

#include <string>
#include <vector>

namespace REMU {

struct EmuLibInfo
{
    std::string verilog_include_path;
    std::vector<std::string> model_sources;
    std::vector<std::string> system_sources;

    static EmuLibInfo& get_instance() { return instance; }

private:

    static EmuLibInfo instance;
    EmuLibInfo();
};

};

#endif // #ifndef _EMULIB_H_
