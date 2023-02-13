#ifndef _FASTARRAY_H_
#define _FASTARRAY_H_

#include <iostream>
#include "bitvector.h"

namespace REMU {

class FastArray
{
    BitVectorArray data;

public:

    uint64_t width() const
    {
        return data.width();
    }

    uint64_t depth() const
    {
        return data.depth();
    }

    void clear()
    {
        data.clear();
    }

    BitVector read(uint64_t index) const
    {
        return data.get(index);
    }

    void write(uint64_t index, const BitVector &value)
    {
        data.set(index, value);
    }

    bool load(std::istream &stream)
    {
        stream.read(reinterpret_cast<char *>(data.to_ptr()), data.blks() * 8);
        return !stream.fail();
    }

    bool save(std::ostream &stream) const
    {
        stream.write(reinterpret_cast<const char *>(data.to_ptr()), data.blks() * 8);
        return !stream.fail();
    }

    FastArray(uint64_t width, uint64_t depth) : data(width, depth) {}
};

}

#endif