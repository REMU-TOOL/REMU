#include "bitvector.h"

using namespace Emu;

namespace {

// modified from https://stackoverflow.com/questions/1392059/algorithm-to-generate-bit-mask
constexpr uint64_t bitmask(uint64_t onecount)
{
    return static_cast<uint64_t>(-(onecount != 0))
        & (static_cast<uint64_t>(-1) >> (64 - onecount));
}

inline void setbits(uint64_t &value, uint64_t new_value, uint64_t width, uint64_t offset)
{
    uint64_t mask = bitmask(width) << offset;
    value = (value & ~mask) | ((new_value << offset) & mask);
}

class BitsReader
{
    using width_t = BitVector::width_t;

    const uint64_t *data;
    uint64_t buf;
    width_t buflen;

public:

    BitsReader(const uint64_t *data)
        : data(data), buf(0), buflen(0) {}

    uint64_t read(width_t len)
    {
        uint64_t result = 0;
        width_t offset = 0;
        if (len > buflen) {
            setbits(result, buf, buflen, 0);
            offset = buflen;
            len -= buflen;
            buf = *data++;
            buflen = 64;
        }
        setbits(result, buf, len, offset);
        buf >>= len;
        buflen -= len;
        return result;
    }
};

};

void BitVector::copy(width_t width, uint64_t *to_data, width_t to_offset, const uint64_t *from_data, width_t from_offset)
{
    if (width == 0)
        return;

    // move to the first block
    from_data += from_offset / 64;
    from_offset %= 64;
    to_data += to_offset / 64;
    to_offset %= 64;

    //          256  block 3  192  block 2  128  block 1  64   block 0   0
    // to_data:  |             |             |             |             |
    //                     ^   ^                           ^    ^
    //   to_offset + width |---|                           |----| to_offset
    //                 trailing piece                   leading piece

    BitsReader reader(from_data);
    reader.read(from_offset); // skip from_offset bits

    // copy the leading piece

    if (to_offset > 0) {
        width_t leading = std::min(64 - to_offset, width);
        setbits(*to_data++, reader.read(leading), leading, to_offset);
        width -= leading;
    }

    // copy the middle blocks

    while (width >= 64) {
        *to_data++ = reader.read(64);
        width -= 64;
    }

    // copy the trailing piece

    if (width > 0) {
        setbits(*to_data, reader.read(width), width, 0);
    }
}
