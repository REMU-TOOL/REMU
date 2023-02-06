#ifndef _DRIVER_COSIM_H_
#define _DRIVER_COSIM_H_

#include "uma.h"

namespace REMU {

class CosimBFM
{
    int m_cid;

public:

    void read(char *buf, size_t offset, size_t len);
    void write(const char *buf, size_t offset, size_t len);
    void fill(char c, size_t offset, size_t len);

    CosimBFM(int cid);
    ~CosimBFM();
};

class CosimUserMem : public UserMem
{
    CosimBFM bfm;
    size_t m_size;

public:

    virtual void read(char *buf, size_t offset, size_t len) override
    {
        bfm.read(buf, offset, len);
    }

    virtual void write(const char *buf, size_t offset, size_t len) override
    {
        bfm.write(buf, offset, len);
    }

    virtual void fill(char c, size_t offset, size_t len) override
    {
        bfm.fill(c, offset, len);
    }

    virtual size_t size() const override
    {
        return m_size;
    }

    CosimUserMem(int cid, size_t size) : bfm(cid), m_size(size) {}
};

class CosimUserIO : public UserIO
{
    CosimBFM bfm;

public:

    virtual uint32_t read(size_t offset) override
    {
        uint32_t val;
        bfm.read(reinterpret_cast<char*>(&val), offset, 4);
        return val;
    }

    virtual void write(size_t offset, uint32_t value) override
    {
        bfm.write(reinterpret_cast<char*>(&value), offset, 4);
    }

    CosimUserIO(int cid) : bfm(cid) {}
};


};

#endif
