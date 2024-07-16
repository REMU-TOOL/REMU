#ifndef _TPARSER_H_
#define _TPARSER_H_

#include "emu_info.h"

namespace REMU {

    class TParser
    {
        std::unordered_map<std::pair<std::string, size_t>, size_t> traceport_info;// <port_name, port_width> -> seq
        uint64_t current_tick;


    public:

        bool run();

        TParser(const SysInfo &sysinfo, const std::string &trace_path);
    };

}

#endif
