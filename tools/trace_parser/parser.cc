#include "parser.h"
#include "cereal/external/rapidjson/error/error.h"
#include "emu_utils.h"

#include <cstddef>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <ostream>
#include <random>
#include <string>
#include <iomanip> 
#include <vector>

using namespace REMU;

bool TParser::run()
{
    int pos = 0;
    std::ifstream file(trace_file, std::ios::binary);
    if (!file) {
        std::cerr << "Can't open trace file: "<< trace_file << std::endl;
        return false;
    }
    uint64_t data;
    uint64_t low_mask = 0xffffffff;
    uint64_t high_mask = 0xffffffff00000000;

    while(true){
        file.seekg(pos, std::ios::beg);
        file.read(reinterpret_cast<char*>(&data), sizeof(data));
        if((data & low_mask) == cycle_flag){
            current_tick = (data & high_mask)>>32;
            std::cout << "Current cycle: " << current_tick << std::endl;
            pos = pos + 8;
            file.seekg(pos, std::ios::beg);
            char channel;
            file.read(&channel, 1);
            std::cout << "Channel: " << trace_info[(int)channel].first << ", width: " << trace_info[(int)channel].second << std::endl;
            int width = trace_info[(int)channel].second/8;
            std::vector<char> buffer(width);
            file.read(buffer.data(), width);
            printf("0x");
            for (int i = width - 1; i >= 0 ; i--) {
                printf("%x", buffer[i]);
            }
            printf("\n");
            pos += width;
            pos += 16 - pos % 16;
        }else{
            return true;
        }
    }
    return true;
}

bool TParser::trace_end(size_t offset){
    size_t width = 128;
    //auto data = raw_trace.substr(offset, width);
}

size_t TParser::parsing_channel(size_t offset, size_t align_size){
    //parsing per cycle trace 
    size_t pos = offset;
    /*std::cout << std::hex << raw_trace[pos] << std::endl;
    while((unsigned char)raw_trace[pos] != 128){
        size_t seq = (unsigned char) raw_trace[pos];
        auto info = trace_info[seq];
        std::cout << "Channel " << info.first << ":"<< std::endl;
        size_t width = info.second;
        auto data = raw_trace.substr(pos, width);
        std::cout << std::hex << data << std::endl;
        pos += width;
    }
    auto timestamp = raw_trace.substr(pos, 4);
    int tick = std::stoi(timestamp, 0, 16);
    std::cout << std::hex << tick << std::endl;
    pos = (pos + align_size - 1) & ~(align_size - 1);
    return pos;*/
}

TParser::TParser(const SysInfo &sysinfo, const std::string &trace_path) 
{
    // Reading port_name, port_width and port seq from sysinfo;
    // Aligning port_width to bytes
    // Reading raw trace from trace file
    size_t i = 0;
    for (auto &info : sysinfo.trace) {
        size_t format_width = (info.port_width + 7) & ~7;
        auto value = std::make_pair(info.port_name, format_width);
        trace_info.push_back(value);
    }
    trace_file = trace_path;
}
