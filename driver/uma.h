#ifndef _DRIVER_UMA_H_
#define _DRIVER_UMA_H_

// User-mode Memory Access

#include <cstdint>
#include <iostream>

namespace REMU {

class UserMem
{
public:
    virtual void read(char *buf, uint64_t offset, uint64_t len) = 0;
    virtual void write(const char *buf, uint64_t offset, uint64_t len) = 0;
    virtual void fill(char c, uint64_t offset, uint64_t len) = 0;
    virtual uint64_t size() const = 0;
    virtual uint64_t dmabase() const = 0;
    virtual ~UserMem() {}

    virtual uint64_t copy_from_stream(uint64_t offset, uint64_t len, std::istream &stream);
    virtual uint64_t copy_to_stream(uint64_t offset, uint64_t len, std::ostream &stream);
};

class UserIO
{
public:
    virtual uint32_t read(uint64_t offset) = 0;
    virtual void write(uint64_t offset, uint32_t value) = 0;
    virtual ~UserIO() {}
};

};

#endif
