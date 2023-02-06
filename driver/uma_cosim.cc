#include "uma_cosim.h"
#include "cosim_bfm_api.h"

#include <cstring>

using namespace REMU;

CosimBFM::CosimBFM(int cid) : m_cid(cid)
{
    bfm_set_verbose(1);
    bfm_open(cid);
    bfm_barrier(cid);
}

CosimBFM::~CosimBFM()
{
    bfm_close(m_cid);
}

void CosimBFM::read(char *buf, size_t offset, size_t len)
{
    auto p = reinterpret_cast<uint8_t*>(buf);
    unsigned int n = (4 - (offset % 4)) % 4;
    if (n != 0 && len >= n) {
        bfm_read_core(m_cid, 0, offset, p, 1, n, 0);
        p += n;
        offset += n;
        len -= n;
    }
    while (len >= 4) {
        // 4-byte transfer
        n = len / 4;
        if (n > 256) n = 256;
        bfm_read_core(m_cid, 0, offset, p, 4, n, 0);
        p += n * 4;
        offset += n * 4;
        len -= n * 4;
    }
    if (len > 0) {
        bfm_read_core(m_cid, 0, offset, p, 1, n, 0);
    }
}

void CosimBFM::write(const char *buf, size_t offset, size_t len)
{
    auto p = reinterpret_cast<uint8_t*>(const_cast<char*>(buf));
    unsigned int n = (4 - (offset % 4)) % 4;
    if (n != 0 && len >= n) {
        bfm_write_core(m_cid, 0, offset, p, 1, n, 0);
        p += n;
        offset += n;
        len -= n;
    }
    while (len >= 4) {
        // 4-byte transfer
        n = len / 4;
        if (n > 256) n = 256;
        bfm_write_core(m_cid, 0, offset, p, 4, n, 0);
        p += n * 4;
        offset += n * 4;
        len -= n * 4;
    }
    if (len > 0) {
        bfm_write_core(m_cid, 0, offset, p, 1, n, 0);
    }
}

void CosimBFM::fill(char c, size_t offset, size_t len)
{
    uint8_t arr[4*256];
    memset(arr, c, 4*256);
    unsigned int n = (4 - (offset % 4)) % 4;
    if (n != 0 && len >= n) {
        bfm_write_core(m_cid, 0, offset, arr, 1, n, 0);
        offset += n;
        len -= n;
    }
    while (len >= 4) {
        // 4-byte transfer
        n = len / 4;
        if (n > 256) n = 256;
        bfm_write_core(m_cid, 0, offset, arr, 4, n, 0);
        offset += n * 4;
        len -= n * 4;
    }
    if (len > 0) {
        bfm_write_core(m_cid, 0, offset, arr, 1, n, 0);
    }
}
