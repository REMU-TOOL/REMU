#include "cosim.h"

#include <cstdio>

#ifdef COSIM_DEBUG
#define PRINTF printf
#else
#define PRINTF(...)
#endif

using namespace boost::interprocess;
using namespace REMU;

const char *mq_req_name     = "remu_cosim_mq_req";
const char *mq_resp_name    = "remu_cosim_mq_resp";
const char *shm_name        = "remu_cosim_shm";

void CosimServer::remover::remove()
{
    message_queue::remove(mq_req_name);
    message_queue::remove(mq_resp_name);
    shared_memory_object::remove(shm_name);
}

bool CosimServer::poll_req(CosimMsgReq &req)
{
    unsigned long recvd_size;
    unsigned int priority;

    bool result = mq_req.try_receive(
        &req, sizeof(req), recvd_size, priority);

    if (result) {
        PRINTF("Server recv req: type=%d, addr=0x%x, value=0x%x\n",
            req.type, req.addr, req.value);
    }

    return result;
}

void CosimServer::send_resp(const CosimMsgResp &resp)
{
    PRINTF("Server send resp: type=%d, value=0x%x\n",
        resp.type, resp.value);
    mq_resp.send(&resp, sizeof(resp), 0);
}

CosimServer::CosimServer(unsigned long mem_size) :
    mq_req(create_only, mq_req_name, 16, sizeof(CosimMsgReq)),
    mq_resp(create_only, mq_resp_name, 16, sizeof(CosimMsgResp)),
    shm(create_only, shm_name, read_write)
{
    shm.truncate(mem_size);
    region = mapped_region(shm, read_write, 0, mem_size);
}

void CosimClient::send_req(const CosimMsgReq &req)
{
    PRINTF("Client send req: type=%d, addr=0x%x, value=0x%x\n",
        req.type, req.addr, req.value);
    mq_req.send(&req, sizeof(req), 0);
}

void CosimClient::recv_resp(CosimMsgResp &resp)
{
    unsigned long recvd_size;
    unsigned int priority;

    mq_resp.receive(&resp, sizeof(resp), recvd_size, priority);
    PRINTF("Client recv resp: type=%d, value=0x%x\n",
        resp.type, resp.value);
}

uint32_t CosimClient::reg_read(uint32_t addr)
{
    CosimMsgReq req = {
        .type   = RegRead,
        .value  = 0,
        .addr   = addr,
    };
    send_req(req);

    CosimMsgResp resp;
    recv_resp(resp);

    return resp.value;
}

void CosimClient::reg_write(uint32_t addr, uint32_t value)
{
    CosimMsgReq req = {
        .type   = RegWrite,
        .value  = value,
        .addr   = addr,
    };
    send_req(req);

    CosimMsgResp resp;
    recv_resp(resp);
}

CosimClient::CosimClient() :
    mq_req(open_only, mq_req_name),
    mq_resp(open_only, mq_resp_name),
    shm(open_only, shm_name, read_write)
{
    offset_t size = 0;
    shm.get_size(size);
    region = mapped_region(shm, read_write, 0, size);
}

CosimClient::~CosimClient()
{
    CosimMsgReq req = {
        .type   = Exit,
        .value  = 0,
        .addr   = 0,
    };
    send_req(req);
}
