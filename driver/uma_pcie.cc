#include "uma_pcie.h"
#include "emu_utils.h"

#include <cstdio>
#include <iostream>
#include <stdexcept>
#include <algorithm>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

using namespace REMU;

void PCIeDMAUserMem::read(char *buf, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("memory access out of range");

    ::lseek(c2h_fd, mem_base + offset, SEEK_SET);
    ::read(c2h_fd, buf, len);
}

void PCIeDMAUserMem::write(const char *buf, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("memory access out of range");

    ::lseek(h2c_fd, mem_base + offset, SEEK_SET);
    ::write(h2c_fd, buf, len);
}

void PCIeDMAUserMem::fill(char c, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("memory access out of range");

    uint64_t bufsz = std::min(len, 0x100000UL);
    auto buf = new char[bufsz];
    std::fill_n(buf, bufsz, 0);

    while (len > 0) {
        uint64_t slice = std::min(bufsz, len);
        ::lseek(h2c_fd, mem_base + offset, SEEK_SET);
        ::write(h2c_fd, buf, slice);
        offset += slice;
        len -= slice;
    }

    delete[] buf;
}

PCIeDMAUserMem::PCIeDMAUserMem(uint64_t mem_base, uint64_t mem_size, std::string c2h, std::string h2c)
    : mem_base(mem_base), mem_size(mem_size)
{
    c2h_fd = ::open(c2h.c_str(), O_RDWR);
    if (c2h_fd < 0)
        throw std::system_error(errno, std::generic_category(), "failed to open " + c2h);

    h2c_fd = ::open(h2c.c_str(), O_RDWR);
    if (h2c_fd < 0)
        throw std::system_error(errno, std::generic_category(), "failed to open " + h2c);
}

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
