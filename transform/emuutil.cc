#include "emuutil.h"

USING_YOSYS_NAMESPACE

using namespace EmuUtil;

std::string EmuUtil::get_sig_src(SigSpec sig) {
    std::stringstream s;
    for (auto &c : sig.chunks()) {
        log_assert(c.is_wire());
        s << c.wire->name.str() << " " << c.offset << " " << c.width << " ";
    }
    return s.str();
}
