#ifndef _EMU_TRANSFORM_H_
#define _EMU_TRANSFORM_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"
#include "escape.h"
#include <sstream>

namespace Yosys {

inline bool is_public_id(IdString id)
{
    return id[0] == '\\';
}

inline std::string str_id(IdString id)
{
    if (is_public_id(id))
        return id.str().substr(1);
    else
        return id.str();
}

// FIXME: Use verilog_hier_name
// This is a workaround to handle hierarchical names in genblks as yosys can only generate
// such information in escaped ids. This breaks the support of escaped ids in user design.
inline std::string simple_hier_name(const std::vector<std::string> &hier)
{
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

inline std::string pretty_name(IdString id, bool escape = true)
{
    std::string res = id[0] == '\\' ? id.substr(1) : id.str();
    if (escape)
        return Escape::escape_verilog_id(res);
    else
        return res;
}

inline std::string pretty_name(std::vector<IdString> path, bool escape = true)
{
    std::ostringstream ss;
    bool first = true;
    for (auto name : path) {
        if (first)
            first = false;
        else
            ss << ".";
        ss << pretty_name(name, escape);
    }
    return ss.str();
}

template <typename T> inline std::string pretty_name(T* obj, bool escape = true)
{
    return pretty_name(obj->name, escape);
}

inline std::string pretty_name(SigBit bit, bool escape = true)
{
    if (bit.is_wire()) {
        std::ostringstream ss;
        ss << pretty_name(bit.wire, escape);
        if (bit.wire->width != 1)
            ss << stringf("[%d]", bit.wire->start_offset + bit.offset);
        return ss.str();
    }
    else
        return Const(bit.data).as_string();
}

inline std::string pretty_name(SigChunk chunk, bool escape = true)
{
    if (chunk.is_wire()) {
        std::ostringstream ss;
        ss << pretty_name(chunk.wire, escape);
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

inline std::string pretty_name(SigSpec spec, bool escape = true)
{
    auto &chunks = spec.chunks();
    if (chunks.size() == 1)
        return pretty_name(chunks.at(0), escape);
    std::ostringstream ss;
    ss << "{";
    bool first = true;
    for (auto it = chunks.rbegin(), ie = chunks.rend(); it != ie; ++it) {
        if (first)
            first = false;
        else
            ss << ", ";
        ss << pretty_name(*it, escape);
    }
    ss << "}";
    return ss.str();
}

inline void make_internal(Wire *wire)
{
    wire->port_input = false;
    wire->port_output = false;
}

inline std::string id2str(IdString id)
{
    return id[0] == '\\' ? id.substr(1) : id.str();
}

inline uint64_t const_as_u64(const Const &c)
{
	uint64_t ret = 0;
	for (size_t i = 0; i < c.bits.size() && i < 64; i++)
		if (c.bits[i] == State::S1)
			ret |= 1 << i;
	return ret;
}

} // namespace Yosys

namespace REMU {

inline std::vector<std::string> split_string(std::string s, char delim)
{
    std::vector<std::string> result;
    size_t start = 0, end = 0;
    while ((end = s.find(delim, start)) != std::string::npos) {
        result.push_back(s.substr(start, end));
        start = end + 1;
    }
    result.push_back(s.substr(start));
    return result;
}

inline std::string join_string(const std::vector<std::string> &vec, char delim)
{
    std::ostringstream ss;
    bool first = true;
    for (auto &s : vec) {
        if (first)
            first = false;
        else
            ss << delim;
        ss << s;
    }
    return ss.str();
}

} // namespace REMU

#endif // #ifndef _EMU_TRANSFORM_H_
