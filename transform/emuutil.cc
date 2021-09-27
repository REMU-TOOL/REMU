#include "emuutil.h"

USING_YOSYS_NAMESPACE

using namespace EmuUtil;

std::string EmuUtil::dump_sig(SigSpec sig) {
    std::stringstream s;
    for (auto &c : sig.chunks()) {
        log_assert(c.is_wire());
        s << c.wire->name.str() << " " << c.offset << " " << c.width << " ";
    }
    return s.str();
}
