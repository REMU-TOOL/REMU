#ifndef _EMU_H_
#define _EMU_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"

namespace Emu {

bool is_public_id(Yosys::IdString id);
std::string str_id(Yosys::IdString id);

std::string simple_hier_name(const std::vector<std::string> &hier);

std::string pretty_name(Yosys::IdString id);
template <typename T> std::string pretty_name(T* obj) { return pretty_name(obj->name); }
std::string pretty_name(Yosys::SigBit bit);
std::string pretty_name(Yosys::SigChunk chunk);
std::string pretty_name(Yosys::SigSpec spec);

std::vector<std::string> split_string(std::string s, char delim);

} // namespace Emu

#endif // #ifndef _EMU_H_
