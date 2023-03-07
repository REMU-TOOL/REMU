#include "uma_devmem.h"

#include <cstring>

#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>

#include <stdexcept>
#include <system_error>

using namespace REMU;

template<typename T>
void slow_memcpy_aligned(volatile void *dst, const volatile void *src, size_t n)
{
    auto new_dst = reinterpret_cast<volatile T*>(dst);
    auto new_src = reinterpret_cast<const volatile T*>(src);
    for (size_t i=0; i<n/sizeof(T); i++)
        new_dst[i] = new_src[i];
}

static void slow_memcpy(volatile void *dst, const volatile void *src, size_t n)
{
    auto dst_addr = reinterpret_cast<size_t>(dst);
    auto src_addr = reinterpret_cast<size_t>(src);
    if (dst_addr % 8 == 0 && src_addr % 8 == 0 && n % 8 == 0)
        slow_memcpy_aligned<uint64_t>(dst, src, n);
    else if (dst_addr % 4 == 0 && src_addr % 4 == 0 && n % 4 == 0)
        slow_memcpy_aligned<uint32_t>(dst, src, n);
    else if (dst_addr % 2 == 0 && src_addr % 2 == 0 && n % 2 == 0)
        slow_memcpy_aligned<uint16_t>(dst, src, n);
    else
        slow_memcpy_aligned<uint8_t>(dst, src, n);
}

template<typename T>
void slow_memset_aligned(volatile void *p, char c, size_t n)
{
    T val = 0;
    for (size_t i=0; i<sizeof(T); i++) {
        val <<= 8;
        val |= c;
    }

    auto new_p = reinterpret_cast<volatile T*>(p);
    for (size_t i=0; i<n/sizeof(T); i++)
        new_p[i] = val;
}

static void slow_memset(volatile void *p, char c, size_t n)
{
    auto addr = reinterpret_cast<size_t>(p);
    if (addr % 8 == 0 && n % 8 == 0)
        slow_memset_aligned<uint64_t>(p, c, n);
    else if (addr % 4 == 0 && n % 4 == 0)
        slow_memset_aligned<uint32_t>(p, c, n);
    else if (addr % 2 == 0 && n % 2 == 0)
        slow_memset_aligned<uint16_t>(p, c, n);
    else
        slow_memset_aligned<uint8_t>(p, c, n);
}

DevMem::DevMem(size_t base, size_t size, bool sync)
{
    size_t pg_size = sysconf(_SC_PAGE_SIZE);
    if (base % pg_size != 0)
        throw std::invalid_argument("base must be a multiple of system page size");

    m_base = base;
    m_size = size;
    m_sync = sync;

    if (geteuid() != 0)
        throw std::runtime_error("root permission is required") ;

    int flag = O_RDWR;
    if (sync)
        flag |= O_SYNC;

    m_fd = open("/dev/mem", flag);
    if (m_fd < 0)
        throw std::system_error(errno, std::generic_category(), "failed to open /dev/mem");

    m_ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, base);
    if (m_ptr == MAP_FAILED) {
        close(m_fd);
        throw std::system_error(errno, std::generic_category(), "failed to mmap /dev/mem");
    }
}

DevMem::~DevMem()
{
    munmap(m_ptr, m_size);
    close(m_fd);
}

void DevMem::read(char *buf, size_t offset, size_t len)
{
    if (m_sync)
        slow_memcpy(buf, ((char *)m_ptr) + offset, len);
    else
        memcpy(buf, ((char *)m_ptr) + offset, len);
}

void DevMem::write(const char *buf, size_t offset, size_t len)
{
    if (m_sync)
        slow_memcpy(((char *)m_ptr) + offset, buf, len);
    else
        memcpy(((char *)m_ptr) + offset, buf, len);
}

uint32_t DevMem::read_u32(size_t offset)
{
    if (offset & 0x3 != 0)
        throw std::invalid_argument("offset must be a multiple of 4");

    return ((volatile uint32_t *)m_ptr)[offset >> 2];
}

void DevMem::write_u32(size_t offset, uint32_t value)
{
    if (offset & 0x3 != 0)
        throw std::invalid_argument("offset must be a multiple of 4");

    ((volatile uint32_t *)m_ptr)[offset >> 2] = value;
}

void DevMem::fill(char c, size_t offset, size_t len)
{
    if (m_sync) {
        slow_memset((char *)m_ptr + offset, c, len);
    }
    else {
        memset((char *)m_ptr + offset, c, len);
    }
}
