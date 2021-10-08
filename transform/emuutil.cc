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

SrcInfoChunk EmuUtil::SrcInfoChunk::extract(int offset, int length) {
    return SrcInfoChunk(name, this->offset + offset, length);
}

EmuUtil::SrcInfo::SrcInfo(SigSpec sig) {
    for (auto &c : sig.chunks()) {
        info.push_back(c);
    }
}

EmuUtil::SrcInfo::SrcInfo(std::string str) {
    std::istringstream s(str);
    std::string name;
    int offset, width;
    while (s >> name && s >> offset && s >> width)
        info.push_back(SrcInfoChunk(name, offset, width));
}

EmuUtil::SrcInfo::operator std::string() {
    std::ostringstream s;
    bool first = true;
    for (auto &c : info) {
        if (c.name.empty())
            continue;
        if (first)
            first = false;
        else
            s << " ";
        s << c.name << " " << c.offset << " " << c.width;
    }
    return s.str();
}

SrcInfo EmuUtil::SrcInfo::extract(int offset, int length) {
    SrcInfo res;
    auto it = info.begin();
    int chunkoff = 0, chunklen = 0;
    while (offset > 0) {
        if (it->width > offset) {
            chunkoff = offset;
            offset = 0;
        }
        else {
            offset -= it->width;
            ++it;
        }
    }
    while (length > 0) {
        if (it->width > length) {
            chunklen = length;
            length = 0;
        }
        else {
            chunklen = it->width;
            length -= chunklen;
        }
        res.info.push_back(it->extract(chunkoff, chunklen));
        chunkoff = 0;
        ++it;
    }
    return res;
}
