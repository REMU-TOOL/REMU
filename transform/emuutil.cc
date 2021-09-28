#include "emuutil.h"

USING_YOSYS_NAMESPACE

using namespace EmuUtil;

std::string EmuUtil::get_sig_src(SigSpec sig) {
    std::ostringstream s;
    bool first = true;
    for (auto &c : sig.chunks()) {
        log_assert(c.is_wire());
        if (first)
            first = false;
        else
            s << " ";
        s << c.wire->name.str() << " " << c.offset << " " << c.width;
    }
    return s.str();
}

std::vector<std::tuple<std::string, int, int>> EmuUtil::parse_sig_src(std::string src) {
    std::vector<std::tuple<std::string, int, int>> res;
    std::istringstream s(src);
    std::string name;
    int offset, width;
    while (s >> name && s >> offset && s >> width)
        res.push_back({name, offset, width});
    return res;
}
