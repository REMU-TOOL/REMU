#ifndef _TPARSER_H_
#define _TPARSER_H_

#include "emu_info.h"
#include <cstddef>
#include <cstdint>
#include <fstream>
#include <string>

namespace REMU {

    class TParser
    {
        std::vector<std::pair<std::string, size_t>> trace_info;// seq -> <port_name, port_width> 
        uint64_t current_tick;
        uint32_t cycle_flag = 0x00100080;
        std::string trace_file;
        bool trace_end(size_t offset);
        size_t parsing_channel(size_t offset, size_t align_size);

    public:

        bool run();

        TParser(const SysInfo &sysinfo, const std::string &trace_path);
    };

}

#endif
