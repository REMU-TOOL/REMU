#ifndef _BITVECTOR_H_
#define _BITVECTOR_H_

#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>
#include <iomanip>
#include <sstream>
#include <stdexcept>
#include <utility>
#include <vector>

namespace REMU {

namespace BitVectorUtils {
uint64_t uint64_rand();
uint8_t uint8_rand();
size_t size_rand();

template <typename T> constexpr T bitmask(size_t onecount) {
  return static_cast<T>(-(onecount != 0)) &
         (static_cast<T>(-1) >> (sizeof(T) * 8 - onecount));
}
} // namespace BitVectorUtils

class BitVector
{

public:

    using width_t = uint64_t;

private:

    // The width of the vector, in bits
    width_t width_;

    union data_or_value {
        uint64_t *data; // If width > 64
        uint64_t value; // Otherwise
    } u;

    bool use_ptr() const { return width_ > 64; }

    static void copy(width_t width, uint64_t *to_data, width_t to_offset, const uint64_t *from_data, width_t from_offset);

    friend void swap(BitVector &first, BitVector &second) noexcept
    {
        std::swap(first.width_, second.width_);
        std::swap(first.u, second.u);
    }

public:

    uint64_t *to_ptr() { return use_ptr() ? u.data : &u.value; }
    const uint64_t *to_ptr() const { return use_ptr() ? u.data : &u.value; }
    size_t blks() const { return (width_ + 63) / 64; }

    width_t width() const { return width_; }

    [[nodiscard]] size_t n_bytes() const { return (width() + 8 - 1) / 8; }

    operator uint64_t() const
    {
        return *to_ptr();
    }

    std::string bin() const
    {
        std::string res(width_, '0');
        auto first = to_ptr();
        auto last = first + blks() - 1;
        width_t pos = 0;
        for (auto p = first; p <= last; p++) {
            auto value = *p;
            for (int i = 0; i < 64; i++) {
                if (pos >= width_)
                    break;
                if (value & 1)
                    res[width_-1-pos] = '1';
                pos++;
                value >>= 1;
            }
        }
        return res;
    }

    std::string hex() const
    {
        size_t hexw = (width_ + 3) / 4;
        std::string res(hexw, '0');
        auto first = to_ptr();
        auto last = first + blks() - 1;
        width_t pos = 0;
        for (auto p = first; p <= last; p++) {
            auto value = *p;
            for (int i = 0; i < 16; i++) {
                if (pos >= hexw)
                    break;
                char digit = value & 0xf;
                res[hexw-1-pos] = digit >= 10 ? digit - 10 + 'a' : digit + '0';
                pos++;
                value >>= 4;
            }
        }
        return res;
    }

    std::string decode_string() const
    {
        std::string s;
        s.reserve(width_/8);
        for (width_t i = 0; i < width_; i += 8) {
            char ch = 0;
            for (width_t j = 0; j < 8 && i+j < width_; j++)
                if (getBit(i+j))
                    ch |= 1 << j;
            if (ch != 0)
                s += ch;
        }
        std::reverse(s.begin(), s.end());
        return s;
    }

    // This sets all bits to 0
    void clear()
    {
        if (use_ptr())
            std::fill_n(u.data, blks(), 0);
        else
            u.value = 0;
    }

    // This gets the specified bit in boolean value
    bool getBit(width_t offset) const
    {
        if (offset >= width_)
            throw std::out_of_range("offset out of range");

        return (to_ptr()[offset / 64] >> (offset % 64)) & 1;
    }

    // This sets the specified bit to the boolean value
    void setBit(width_t offset, bool value)
    {
        if (offset >= width_)
            throw std::out_of_range("offset out of range");

        uint64_t &ref = to_ptr()[offset / 64];
        uint64_t bit = uint64_t(1) << offset;
        if (value)
            ref |= bit;
        else
            ref &= ~bit;
    }

    // This gets the width bits starting from offset to data array, and return data itself
    uint64_t *getValue(width_t offset, width_t width, uint64_t *data) const
    {
        if (offset + width > width_)
            throw std::out_of_range("selection out of range");

        copy(width, data, 0, to_ptr(), offset);

        return data;
    }

    // This gets the width bits starting from offset
    BitVector getValue(width_t offset, width_t width) const
    {
        BitVector result(width);
        getValue(offset, width, result.to_ptr());

        return result;
    }

    // This sets the width bits starting from offset to data array
    void setValue(width_t offset, width_t width, const uint64_t *data)
    {
        if (offset + width > width_)
            throw std::out_of_range("selection out of range");

        copy(width, to_ptr(), offset, data, 0);
    }

    // This sets the width bits starting from offset to value
    void setValue(width_t offset, width_t width, uint64_t value)
    {
        if (width > 64)
            throw std::out_of_range("selection out of range");

        setValue(offset, width, &value);
    }

    // This sets the bits starting from offset to value
    void setValue(width_t offset, const BitVector &value)
    {
        setValue(offset, value.width_, value.to_ptr());
    }

    // This constructs an empty 0-wide BitVector
    BitVector() : BitVector(0) {}

    // This constructs an empty BitVector 
    explicit BitVector(width_t width) : width_(width)
    {
        if (use_ptr()) {
            u.data = new uint64_t[blks()];
        }
        clear();
    }

    // This constructs a BitVector and initializes its lowest bits with value
    BitVector(width_t width, uint64_t value) : BitVector(width, &value, 1) {}

    // This constructs a BitVector and initializes its lowest bits with a data array
    BitVector(width_t width, const uint64_t *data, size_t len) : BitVector(width)
    {
        copy(std::min(width, len * 64), to_ptr(), 0, data, 0);
    }

    // This constructs a BitVector and initializes its lowest bits with a initializer list
    BitVector(width_t width, const std::initializer_list<uint64_t> &list)
        : BitVector(width, list.begin(), list.size()) {}

    // This constructs a BitVector with a bit string which consists of 0 and 1
    BitVector(const std::string &bits) : BitVector(bits.size())
    {
        for (size_t i = 0 ; i < width_; i++)
            setBit(i, bits.at(width_ - i - 1) == '1');
    }

    BitVector(const BitVector &other) : BitVector(other.width_, other.to_ptr(), other.blks()) {}

    BitVector(BitVector &&other) noexcept : BitVector()
    {
        swap(*this, other);
    }

    ~BitVector()
    {
        if (use_ptr())
            delete[] u.data;
    }

    BitVector &operator=(const BitVector &other)
    {
        if (this == &other)
            return *this;

        BitVector temp(other);
        swap(*this, temp);
        return *this;
    }

    BitVector &operator=(BitVector &&other) noexcept
    {
        BitVector temp(std::move(other));
        swap(*this, temp);
        return *this;
    }

    bool operator==(const BitVector &other) const
    {
        if (width_ != other.width_)
            return false;

        auto this_data = to_ptr(), other_data = other.to_ptr();
        for (size_t i = 0; i < blks(); i++)
            if (this_data[i] != other_data[i])
                return false;

        return true;
    }

    void rand() {
      if (use_ptr()) {
        for (size_t i = 0; i < blks(); i++) {
          u.data[i] = BitVectorUtils::uint64_rand();
        }
        u.data[blks() - 1] &= BitVectorUtils::bitmask<uint64_t>(width() % 64);
      } else {
        u.value = BitVectorUtils::uint64_rand() &
                  BitVectorUtils::bitmask<uint64_t>(width() % 64);
      }
    }

    // cereal serialization functions

    template<class Archive>
    std::string save_minimal(Archive const &) const
    {
        return bin();
    }

    template<class Archive>
    void load_minimal(Archive const &, std::string const &str)
    {
        *this = str;
    }

};

class BitVectorArray
{

public:

    using width_t = BitVector::width_t;
    using depth_t = int64_t;

private:

    // width of an element, in bits
    width_t width_;

    // number of elements
    depth_t depth_;

    // the first index
    depth_t start_offset_;

    // flattened data
    BitVector data;

public:

    uint64_t *to_ptr() { return data.to_ptr(); }
    const uint64_t *to_ptr() const { return data.to_ptr(); }
    size_t blks() const { return data.blks(); }

    width_t width() const { return width_; }
    depth_t depth() const { return depth_; }
    depth_t start_offset() const { return start_offset_; }

    // set all bits to 0
    void clear()
    {
        data.clear();
    }

    BitVector get(depth_t index) const
    {
        if (index < start_offset_ || index >= start_offset_ + depth_)
            throw std::out_of_range("index out of range");

        return data.getValue(index * width_, width_);
    }

    void set(depth_t index, const BitVector &value)
    {
        if (value.width() != width_)
            throw std::invalid_argument("value width mismatch");

        if (index < start_offset_ || index >= start_offset_ + depth_)
            throw std::out_of_range("index out of range");

        data.setValue(index * width_, value);
    }

    BitVector get_flattened_data() const { return data; }

    void set_flattened_data(const BitVector &value)
    {
        if (value.width() != width_ * depth_)
            throw std::invalid_argument("value width mismatch");

        data = value;
    }

    BitVectorArray() : BitVectorArray(0, 0) {}

    BitVectorArray(width_t width, depth_t depth, depth_t start_offset = 0) :
        width_(width), depth_(depth), start_offset_(start_offset), data(width * depth) {}

};

};

#endif // #ifndef _BITVECTOR_H_
