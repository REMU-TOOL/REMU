#ifndef _REMU_SIGNAL_INFO_H_
#define _REMU_SIGNAL_INFO_H_

#include <cstdint>
#include <map>
#include <iostream>

#include "bitvector.h"

namespace REMU {

struct SignalTraceDB
{
    // signal id -> { tick -> data }
    std::map<int, std::map<uint64_t, BitVector>> trace_data;
    uint64_t record_end;
};

std::ostream& operator<<(std::ostream &stream, const SignalTraceDB &info);
std::istream& operator>>(std::istream &stream, SignalTraceDB &info);

} // namespace REMU

#endif // #ifndef _REMU_SIGNAL_INFO_H_
