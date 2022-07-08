#ifndef _EMU_H_
#define _EMU_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"

namespace Emu {

USING_YOSYS_NAMESPACE

bool is_public_id(IdString id);
std::string str_id(IdString id);

std::string simple_hier_name(const std::vector<std::string> &hier);

} // namespace Emu

#endif // #ifndef _EMU_H_
