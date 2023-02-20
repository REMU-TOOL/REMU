#include "uma.h"

using namespace REMU;

inline constexpr uint64_t bufsize = 4UL*1096*1096;

uint64_t UserMem::copy_from_stream(uint64_t offset, uint64_t len, std::istream &stream)
{
    uint64_t transferred = 0;
    auto buf = new char[bufsize];

    while (len != 0 && !stream.eof()) {
        size_t n = len < bufsize ? len : bufsize;
        stream.read(buf, n);
        n = stream.gcount();
        write(buf, offset, n);
        offset += n;
        transferred += n;
        len -= n;
    }

    delete[] buf;
    return transferred;
}

uint64_t UserMem::copy_to_stream(uint64_t offset, uint64_t len, std::ostream &stream)
{
    uint64_t transferred = 0;
    auto buf = new char[bufsize];

    while (len != 0) {
        size_t n = len < bufsize ? len : bufsize;
        read(buf, offset, n);
        offset += n;
        transferred += n;
        len -= n;
        stream.write(buf, n);
    }

    delete[] buf;
    return transferred;
}
