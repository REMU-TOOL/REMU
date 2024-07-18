#include "parser.h"
#include "cereal/external/rapidjson/error/error.h"
#include "emu_utils.h"

#include <cstddef>
#include <cstdio>
#include <cstring>

using namespace REMU;

bool TParser::run()
{
    size_t pos = 0;
    while(pos < raw_trace.size()){
        pos = parsing_channel(pos, 64);
    }
    return true;
}

std::string TParser::read_trace()
{
    std::ifstream ifile(trace_file, std::ios::binary);
    std::ostringstream buf;
    char ch;
    while(buf && ifile.get(ch))
        buf.put(ch);
    return buf.str();
}

size_t TParser::parsing_channel(size_t offset, size_t align_size){
    //parsing per cycle trace 
    size_t pos = offset;
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
    return pos;
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
        trace_info.insert(std::make_pair(i, value));
    }
    trace_file = trace_path;
    raw_trace = read_trace();
}
