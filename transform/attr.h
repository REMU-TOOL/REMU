#ifndef _ATTR_H_
#define _ATTR_H_

#include "kernel/yosys.h"

namespace REMU {
namespace Attr {
#define DEF(k, v) extern const Yosys::IdString k;
#include "attr.inc"
#undef DEF
};
};

#endif // #ifndef _ATTR_H_
