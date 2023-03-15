#include "uma_cdma.h"

#include <cstdio>
#include <stdexcept>

using namespace REMU;

constexpr int XAXICDMA_CDMACR   = 0x00;
constexpr int XAXICDMA_CDMASR   = 0x04;

constexpr int XAXICDMA_SA       = 0x18;
constexpr int XAXICDMA_SA_MSB   = 0x1c;
constexpr int XAXICDMA_DA       = 0x20;
constexpr int XAXICDMA_DA_MSB   = 0x24;
constexpr int XAXICDMA_BTT      = 0x28;

constexpr uint32_t XAXICDMA_CR_RESET    = 1U << 2;

constexpr uint32_t XAXICDMA_SR_DECERR   = 1U << 6;
constexpr uint32_t XAXICDMA_SR_SLVERR   = 1U << 5;
constexpr uint32_t XAXICDMA_SR_INTERR   = 1U << 4;
constexpr uint32_t XAXICDMA_SR_IDLE     = 1U << 1;

constexpr uint32_t XAXICDMA_SR_ANYERR   =
    XAXICDMA_SR_DECERR | XAXICDMA_SR_SLVERR | XAXICDMA_SR_INTERR;

void CDMAUserMem::cdma_xfer(uint64_t from, uint64_t to, uint32_t len)
{
    if (len > max_xfer_size)
        throw std::invalid_argument("cdma xfer length too big");

    // disable SG & interrupts
    cdma_reg.write(XAXICDMA_CDMACR, 0);

    // check error
    if (cdma_reg.read(XAXICDMA_CDMASR) & XAXICDMA_SR_ANYERR) {
        fprintf(stderr, "[CDMA] WARNING: CDMA error detected, trying to reset CDMA...\n");
        cdma_reg.write(XAXICDMA_CDMACR, XAXICDMA_CR_RESET);
        while (cdma_reg.read(XAXICDMA_CDMACR) & XAXICDMA_CR_RESET);
    }

    cdma_reg.write(XAXICDMA_SA, from);
    cdma_reg.write(XAXICDMA_SA_MSB, from >> 32);

    cdma_reg.write(XAXICDMA_DA, to);
    cdma_reg.write(XAXICDMA_DA_MSB, to >> 32);

    cdma_reg.write(XAXICDMA_BTT, len);

    while (!(cdma_reg.read(XAXICDMA_CDMASR) & XAXICDMA_SR_IDLE));
}

void CDMAUserMem::read(char *buf, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("cdma xfer out of range");

    while (len > 0) {
        uint32_t slice = len > max_xfer_size ? max_xfer_size : len;
        cdma_xfer(mem_base + offset, bounce_mem.dmabase(), slice);
        bounce_mem.read(buf, 0, slice);
        buf += slice;
        offset += slice;
        len -= slice;
    }
}

void CDMAUserMem::write(const char *buf, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("cdma xfer out of range");

    while (len > 0) {
        uint32_t slice = len > max_xfer_size ? max_xfer_size : len;
        bounce_mem.write(buf, 0, slice);
        cdma_xfer(bounce_mem.dmabase(), mem_base + offset, slice);
        buf += slice;
        offset += slice;
        len -= slice;
    }
}

void CDMAUserMem::fill(char c, uint64_t offset, uint64_t len)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("cdma xfer out of range");

    bounce_mem.fill(c, 0, max_xfer_size);

    while (len > 0) {
        uint32_t slice = len > max_xfer_size ? max_xfer_size : len;
        cdma_xfer(bounce_mem.dmabase(), mem_base + offset, slice);
        offset += slice;
        len -= slice;
    }
}

uint64_t CDMAUserMem::copy_from_stream(uint64_t offset, uint64_t len, std::istream &stream)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("cdma xfer out of range");

    uint64_t transferred = 0;

    while (len > 0) {
        uint32_t slice = len > max_xfer_size ? max_xfer_size : len;
        uint32_t actual = bounce_mem.copy_from_stream(0, slice, stream);
        cdma_xfer(bounce_mem.dmabase(), mem_base + offset, actual);

        offset += actual;
        len -= actual;
        transferred += actual;

        if (slice != actual) {
            break;
        }
    }

    return transferred;
}

uint64_t CDMAUserMem::copy_to_stream(uint64_t offset, uint64_t len, std::ostream &stream)
{
    if (offset + len > mem_size)
        throw std::invalid_argument("cdma xfer out of range");

    uint64_t transferred = 0;

    while (len > 0) {
        uint32_t slice = len > max_xfer_size ? max_xfer_size : len;
        cdma_xfer(mem_base + offset, bounce_mem.dmabase(), slice);
        uint32_t actual = bounce_mem.copy_to_stream(0, slice, stream);

        offset += actual;
        len -= actual;
        transferred += actual;

        if (slice != actual) {
            break;
        }
    }

    return transferred;
}
