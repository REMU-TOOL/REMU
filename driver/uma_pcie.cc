#include "uma_pcie.h"
#include "emu_utils.h"

#include <cstdio>
#include <iostream>
#include <stdexcept>
#include <algorithm>

using namespace REMU;

void PCIeBARUserMem::read(char *buf, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("memory access out of range");

    uint64_t bar_size = mem_bar.size();
    uint64_t shift = clog2(bar_size);
    uint64_t seg = offset >> shift;
    offset = offset & ~(~0UL << shift);

    while (len > 0) {
        uint64_t slice = std::min(len, bar_size - offset);
        ctrl_bar.write(ctrl_reg_offset, seg);
        mem_bar.read(buf, offset, slice);
        buf += slice;
        len -= slice;
        seg++;
        offset = 0;
    }
}

void PCIeBARUserMem::write(const char *buf, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("memory access out of range");

    uint64_t bar_size = mem_bar.size();
    uint64_t shift = clog2(bar_size);
    uint64_t seg = offset >> shift;
    offset = offset & ~(~0UL << shift);

    while (len > 0) {
        uint64_t slice = std::min(len, bar_size - offset);
        ctrl_bar.write(ctrl_reg_offset, seg);
        mem_bar.write(buf, offset, slice);
        buf += slice;
        len -= slice;
        seg++;
        offset = 0;
    }
}

void PCIeBARUserMem::fill(char c, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("memory access out of range");

    uint64_t bar_size = mem_bar.size();
    uint64_t shift = clog2(bar_size);
    uint64_t seg = offset >> shift;
    offset = offset & ~(~0UL << shift);

    while (len > 0) {
        uint64_t slice = std::min(len, bar_size - offset);
        ctrl_bar.write(ctrl_reg_offset, seg);
        mem_bar.fill(c, offset, slice);
        len -= slice;
        seg++;
        offset = 0;
    }
}
