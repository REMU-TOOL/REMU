#ifndef _EMU_TRANSFORM_H_
#define _EMU_TRANSFORM_H_

#include "kernel/yosys.h"
#include "kernel/mem.h"
#include "escape.h"
#include <sstream>

#include "emu_utils.h"

namespace Yosys {

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

#endif // #ifndef _EMU_TRANSFORM_H_
