#ifndef _DRIVER_COSIM_H_
#define _DRIVER_COSIM_H_

#include "uma.h"

namespace REMU {

#ifdef ENABLE_COSIM

class CosimUserMem : public UserMem
{

public:

    virtual void read(char *buf, uint64_t offset, uint64_t len) override;
    virtual void write(const char *buf, uint64_t offset, uint64_t len) override;
    virtual void fill(char c, uint64_t offset, uint64_t len) override;

    virtual uint64_t size() const override;
    virtual uint64_t dmabase() const override { return 0; }

    CosimUserMem();
    virtual ~CosimUserMem();
};

class CosimUserIO : public UserIO
{

public:

    virtual uint32_t read(uint64_t offset) override;
    virtual void write(uint64_t offset, uint32_t value) override;

    CosimUserIO();
    virtual ~CosimUserIO();
};

#endif

};

#endif
