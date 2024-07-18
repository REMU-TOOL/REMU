#ifndef _TPARSER_H_
#define _TPARSER_H_

#include "emu_info.h"
#include <cstddef>
#include <fstream>
#include <string>

namespace REMU {

    class TParser
    {
        std::map<size_t, std::pair<std::string, size_t>> trace_info;// seq -> <port_name, port_width> 
        uint64_t current_tick;
        std::string raw_trace;
        std::string read_trace();
        std::string trace_file;
        size_t parsing_channel(size_t offset, size_t align_size);

    public:

        bool run();

        TParser(const SysInfo &sysinfo, const std::string &trace_path);
    };

}

#endif
