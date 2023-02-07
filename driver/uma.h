#ifndef _DRIVER_UMA_H_
#define _DRIVER_UMA_H_

// User-mode Memory Access

#include <cstddef>
#include <cstdint>

namespace REMU {

class UserMem
{
public:
    virtual void read(char *buf, size_t offset, size_t len) = 0;
    virtual void write(const char *buf, size_t offset, size_t len) = 0;
    virtual void fill(char c, size_t offset, size_t len) = 0;
    virtual uint64_t size() const = 0;
    virtual uint64_t dmabase() const = 0;
    virtual ~UserMem() {}
};

class UserIO
{
public:
    virtual uint32_t read(size_t offset) = 0;
    virtual void write(size_t offset, uint32_t value) = 0;
    virtual ~UserIO() {}
};

};

#endif
