#ifndef _COSIM_H_
#define _COSIM_H_

#include <boost/interprocess/ipc/message_queue.hpp>
#include <boost/interprocess/shared_memory_object.hpp>

namespace REMU {

enum CosimMsgType
{
    RegRead,
    RegWrite,
};

struct CosimMsgReq
{
    CosimMsgType    type;
    uint32_t        value;      // for RegWrite
    uint32_t        addr;
};

struct CosimMsgResp
{
    CosimMsgType    type;
    uint32_t        value;      // for RegRead
};

class CosimMemReadWrite
{
protected:
    boost::interprocess::mapped_region region;

public:

    void* mem_ptr()
    {
        return region.get_address();
    }

    size_t mem_size()
    {
        return region.get_size();
    }

    template<typename T>
    T mem_read(uint64_t addr)
    {
        T *p = reinterpret_cast<T*>(region.get_address());
        return p[addr/sizeof(T)];
    }

    template<typename T>
    void mem_write(uint64_t addr, T value)
    {
        T *p = reinterpret_cast<T*>(region.get_address());
        p[addr/sizeof(T)] = value;
    }
};

class CosimServer : public CosimMemReadWrite
{
    struct remover
    {
        void remove();
        remover() { remove(); }
        ~remover() { remove(); }
    } remover_;

    boost::interprocess::message_queue mq_req;
    boost::interprocess::message_queue mq_resp;
    boost::interprocess::shared_memory_object shm;

public:

    bool poll_req(CosimMsgReq &req);
    void send_resp(const CosimMsgResp &resp);

    CosimServer(unsigned long mem_size);
};

class CosimClient : public CosimMemReadWrite
{
    boost::interprocess::message_queue mq_req;
    boost::interprocess::message_queue mq_resp;
    boost::interprocess::shared_memory_object shm;

    void send_req(const CosimMsgReq &req);
    void recv_resp(CosimMsgResp &resp);

public:

    uint32_t reg_read(uint32_t addr);
    void reg_write(uint32_t addr, uint32_t value);

    CosimClient();
};

}

#endif
