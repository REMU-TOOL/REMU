#include "attr.h"

#define DEF(k, v) const Yosys::IdString Emu::Attr::k = v;
#include "attr.inc"
#undef DEF
