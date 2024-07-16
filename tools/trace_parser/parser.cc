#include "parser.h"
#include "tokenizer.h"
#include "emu_utils.h"

#include <cstdio>
#include <cstring>

#include <unordered_map>

using namespace REMU;
namespace tk = Tokenizer;

bool TParser::run()
{
    //TODO: parsering trace file
}


TParser::TParser(const SysInfo &sysinfo, const std::string &trace_path) 
{
    //TODO: Reading port_name, port_width and port seq from sysinfo;
    // Aligning port_width to bytes
}
