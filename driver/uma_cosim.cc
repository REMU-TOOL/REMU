#include "uma_cosim.h"
#include "cosim.h"

#include <cstring>

#include <memory>

using namespace REMU;

std::unique_ptr<CosimClient> client;

inline void setup_client()
{
    if (!client)
        client = std::make_unique<CosimClient>();
}

CosimUserMem::CosimUserMem()
{
    setup_client();
}

CosimUserIO::CosimUserIO()
{
    setup_client();
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


uint32_t CosimUserIO::read(uint64_t offset)
{
    return client->reg_read(offset);
}

void CosimUserIO::write(uint64_t offset, uint32_t value)
{
    client->reg_write(offset, value);
}
