#ifdef ENABLE_COSIM

#include "uma_cosim.h"
#include "cosim.h"

#include <cstring>

#include <memory>

using namespace REMU;

static std::unique_ptr<CosimClient> client;
static unsigned int client_refcount = 0;

inline void start_client()
{
    if (client_refcount == 0)
        client = std::make_unique<CosimClient>();
    client_refcount++;
}

inline void stop_client()
{
    if (client_refcount > 0)
        client_refcount--;
    if (client_refcount == 0)
        client = 0;
}

CosimUserMem::CosimUserMem()
{
    start_client();
}

CosimUserMem::~CosimUserMem()
{
    stop_client();
}

CosimUserIO::CosimUserIO()
{
    start_client();
}

CosimUserIO::~CosimUserIO()
{
    stop_client();
}

void CosimUserMem::read(char *buf, uint64_t offset, uint64_t len)
{
    memcpy(buf, (char*)client->mem_ptr() + offset, len);
}

void CosimUserMem::write(const char *buf, uint64_t offset, uint64_t len)
{
    memcpy((char*)client->mem_ptr() + offset, buf, len);
}

void CosimUserMem::fill(char c, uint64_t offset, uint64_t len)
{
    memset((char*)client->mem_ptr() + offset, c, len);
}

uint64_t CosimUserMem::size() const
{
    return client->mem_size();
}

uint32_t CosimUserIO::read(uint64_t offset)
{
    return client->reg_read(offset);
}

void CosimUserIO::write(uint64_t offset, uint32_t value)
{
    client->reg_write(offset, value);
}

#endif
