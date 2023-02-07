#ifndef _DRIVER_DEVMEM_H_
#define _DRIVER_DEVMEM_H_

#include "uma.h"

namespace REMU {

class DevMem
{
    int m_fd;
    size_t m_base, m_size;
    void *m_ptr;

public:

    size_t base() const { return m_base; }
    size_t size() const { return m_size; }

    void read(char *buf, size_t offset, size_t len);
    void write(const char *buf, size_t offset, size_t len);
    uint32_t read_u32(size_t offset);
    void write_u32(size_t offset, uint32_t value);

    void fill(char c, size_t offset, size_t len);

    DevMem(size_t base, size_t size);
    ~DevMem();
};

class DMUserMem : public UserMem
{
    DevMem dm;
    uint64_t m_dmabase;

public:

    virtual void read(char *buf, size_t offset, size_t len) override
    {
        dm.read(buf, offset, len);
    }

    virtual void write(const char *buf, size_t offset, size_t len) override
    {
        dm.write(buf, offset, len);
    }

    virtual void fill(char c, size_t offset, size_t len) override
    {
        dm.fill(c, offset, len);
    }

    virtual uint64_t size() const override { return dm.size(); }
    virtual uint64_t dmabase() const override { return m_dmabase; }

    DMUserMem(uint64_t base, uint64_t size, uint64_t dmabase) : dm(base, size), m_dmabase(dmabase) {}
};

class DMUserIO : public UserIO
{
    DevMem dm;

public:

    virtual uint32_t read(size_t offset) override
    {
        return dm.read_u32(offset);
    }

    virtual void write(size_t offset, uint32_t value) override
    {
        dm.write_u32(offset, value);
    }

    DMUserIO(size_t base, size_t size) : dm(base, size) {}
};

};

#endif
