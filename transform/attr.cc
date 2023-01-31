#include "attr.h"

#define DEF(k, v) const Yosys::IdString REMU::Attr::k = v;
#include "attr.inc"
#undef DEF
