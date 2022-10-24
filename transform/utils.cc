#include "escape.h"
#include "emu.h"
#include <sstream>

USING_YOSYS_NAMESPACE

namespace Emu {

bool is_public_id(IdString id) {
    return id[0] == '\\';
}

std::string str_id(IdString id) {
    if (is_public_id(id))
        return id.str().substr(1);
    else
        return id.str();
}

// FIXME: Use verilog_hier_name
// This is a workaround to handle hierarchical names in genblks as yosys can only generate
// such information in escaped ids. This breaks the support of escaped ids in user design.
std::string simple_hier_name(const std::vector<std::string> &hier) {
    std::ostringstream os;
    bool first = true;
    for (auto &name : hier) {
        if (first)
            first = false;
        else
            os << ".";
        os << name;
    }
    return os.str();
}

std::string pretty_name(IdString id) {
    return Escape::escape_verilog_id(id[0] == '\\' ? id.substr(1) : id.str());
}

std::string pretty_name(SigBit bit) {
    if (bit.is_wire()) {
        std::ostringstream ss;
        ss << pretty_name(bit.wire);
        if (bit.wire->width != 1)
            ss << stringf("[%d]", bit.wire->start_offset + bit.offset);
        return ss.str();
    }
    else
        return Const(bit.data).as_string();
}

std::string pretty_name(SigChunk chunk) {
    if (chunk.is_wire()) {
        std::ostringstream ss;
        ss << pretty_name(chunk.wire);
        if (chunk.size() != chunk.wire->width) {
            if (chunk.size() == 1)
                ss << stringf("[%d]", chunk.wire->start_offset + chunk.offset);
            else if (chunk.wire->upto)
                ss << stringf("[%d:%d]", (chunk.wire->width - (chunk.offset + chunk.width - 1) - 1) + chunk.wire->start_offset,
                        (chunk.wire->width - chunk.offset - 1) + chunk.wire->start_offset);
            else
                ss << stringf("[%d:%d]", chunk.wire->start_offset + chunk.offset + chunk.width - 1,
                        chunk.wire->start_offset + chunk.offset);
        }
        return ss.str();
    }
    else
        return Const(chunk.data).as_string();
}

std::string pretty_name(SigSpec spec) {
    auto &chunks = spec.chunks();
    if (chunks.size() == 1)
        return pretty_name(chunks.at(0));
    std::ostringstream ss;
    ss << "{";
    bool first = true;
    for (auto it = chunks.rbegin(), ie = chunks.rend(); it != ie; ++it) {
        if (first)
            first = false;
        else
            ss << ", ";
        ss << pretty_name(*it);
    }
    ss << "}";
    return ss.str();
}

#if 0

FfInfo::FfInfo(std::string str, std::vector<std::string> path) {
    std::istringstream s(str);
    FfInfoChunk chunk;
    int name_size;
    while (s >> name_size) {
        chunk.name = path;
        while (name_size--) {
            std::string n;
            s >> n;
            chunk.name.push_back(n);
        }
        s >> chunk.is_dut;
        s >> chunk.offset;
        s >> chunk.width;
        info.push_back(chunk);
    }
    std::string initstr;
    s >> initstr;
    initval.from_string(initstr);
}

FfInfo::operator std::string() {
    std::ostringstream s;
    bool first = true;
    for (auto &c : info) {
        if (c.name.empty())
            continue;
        if (first)
            first = false;
        else
            s << " ";
        s << c.name.size() << " ";
        for (auto &n : c.name)
            s << n << " ";
        s << c.is_dut << " " << c.offset << " " << c.width;
    }
    s << initval.as_string();
    return s.str();
}

FfInfo FfInfo::extract(int offset, int length) {
    FfInfo res;
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

#endif

} // namespace EmuUtil
