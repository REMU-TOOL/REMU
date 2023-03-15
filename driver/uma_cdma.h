#ifndef _DRIVER_UMA_CDMA_H_
#define _DRIVER_UMA_CDMA_H_

#include "uma.h"
#include "uma_devmem.h"

namespace REMU {

class CDMAUserMem : public UserMem
{
    // Region of device memory
    uint64_t mem_base, mem_size;

    // Region of bounce memory with CDMA I/O coherency
    DMUserMemCached bounce_mem;

    // Region of CDMA MMIO registers
    DMUserIO cdma_reg;

    static constexpr uint32_t CDMA_MAX_XFER_SIZE = 0x02000000U;
    uint32_t max_xfer_size; // min(CDMA_MAX_XFER_SIZE, bounce_size)

    void cdma_xfer(uint64_t from, uint64_t to, uint32_t len);

public:

    virtual void read(char *buf, uint64_t offset, uint64_t len) override;
    virtual void write(const char *buf, uint64_t offset, uint64_t len) override;
    virtual void fill(char c, uint64_t offset, uint64_t len) override;

    virtual uint64_t size() const override
    {
        return mem_size;
    }

    virtual uint64_t dmabase() const override
    {
        return mem_base; // TODO: should we consider different base addresses for EMU_SYSTEM & CDMA?
    }

    virtual uint64_t copy_from_stream(uint64_t offset, uint64_t len, std::istream &stream) override;
    virtual uint64_t copy_to_stream(uint64_t offset, uint64_t len, std::ostream &stream) override;

    CDMAUserMem(
        uint64_t mem_base,
        uint64_t mem_size,
        uint64_t bounce_base,
        uint64_t bounce_size,
        uint64_t cdma_base
    ) :
        mem_base(mem_base),
        mem_size(mem_size),
        bounce_mem(bounce_base, bounce_size, bounce_base),
        cdma_reg(cdma_base, 0x1000),
        max_xfer_size(bounce_size > CDMA_MAX_XFER_SIZE ? CDMA_MAX_XFER_SIZE : bounce_size)
    {}
};

}

#endif
