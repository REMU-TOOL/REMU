#ifndef _REMU_SIGNAL_TRACE_H_
#define _REMU_SIGNAL_TRACE_H_

#include <cstdint>
#include <vector>
#include <iostream>

#include "bitvector.h"

namespace REMU {

struct SignalState
{
    uint64_t tick;
    int index;
    BitVector data;
};

using SignalStateList = std::vector<SignalState>;

std::ostream& operator<<(std::ostream &stream, const SignalStateList &info);
std::istream& operator>>(std::istream &stream, SignalStateList &info);

} // namespace REMU

#endif // #ifndef _REMU_SIGNAL_TRACE_H_
