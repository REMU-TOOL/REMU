#ifndef _DRIVER_UMA_PCIE_BAR_H_
#define _DRIVER_UMA_PCIE_BAR_H_

#include "uma.h"
#include "uma_devmem.h"

namespace REMU {

class PCIeDMAUserMem : public UserMem
{
    // Region of device memory
    uint64_t mem_base, mem_size;

    int c2h_fd, h2c_fd;

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
        return mem_base;
    }

    PCIeDMAUserMem(uint64_t mem_base, uint64_t mem_size, std::string c2h, std::string h2c);
};

class PCIeBARUserMem : public UserMem
{
    // Region of device memory
    uint64_t mem_base, mem_size;

    // Region of BAR to access memory
    DMUserMem mem_bar;

    // Region of base address register
    DMUserIO ctrl_bar;
    uint64_t ctrl_reg_offset;

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
        return mem_base;
    }

    PCIeBARUserMem(
        uint64_t mem_base,
        uint64_t mem_size,
        std::string dev_mem_bar,
        std::string dev_ctrl_bar,
        uint64_t mem_bar_size,
        uint64_t ctrl_reg_address
    ) :
        mem_base(mem_base),
        mem_size(mem_size),
        mem_bar(0, mem_bar_size, 0, dev_mem_bar),
        ctrl_bar(ctrl_reg_address & ~0xffful, 1000, dev_ctrl_bar),
        ctrl_reg_offset(ctrl_reg_address & 0xffful)
    {}
};

}

#endif
