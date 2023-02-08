#ifndef _REMU_SIGNAL_TRACE_H_
#define _REMU_SIGNAL_TRACE_H_

#include <cstdint>
#include <vector>
#include <iostream>

#include "bitvector.h"

namespace REMU {

struct SignalTraceData
{
    uint64_t tick;
    int index;
    BitVector data;
};

struct SignalTraceList
{
    std::vector<SignalTraceData> list;
};

std::ostream& operator<<(std::ostream &stream, const SignalTraceList &info);
std::istream& operator>>(std::istream &stream, SignalTraceList &info);

} // namespace REMU

#endif // #ifndef _REMU_SIGNAL_TRACE_H_
