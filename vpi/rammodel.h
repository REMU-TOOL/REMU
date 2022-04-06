#ifndef _RAMMODEL_H_
#define _RAMMODEL_H_

#include <queue>
#include <iostream>
#include <cstdint>
#include <cstring>

namespace Replay {

class RamModel {

public:

    using addr_t    = std::uint64_t;    // max 64
    using data_t    = std::uint64_t;    // max 64
    using id_t      = std::uint16_t;    // max 16
    using strb_t    = std::uint8_t;     // max 8

    static std::uint8_t const INCR  = 1;
    static std::uint8_t const WRAP  = 2;

    struct AChannel {
        addr_t          addr;   // max 64
        id_t            id;     // max 16
        std::uint8_t    len;    // 8
        std::uint8_t    size;   // 3
        std::uint8_t    burst;  // 2
        bool            write;  // 1

        inline addr_t burst_len() const { return len + 1; }
        inline addr_t burst_size() const { return 1 << size; }
    };

    struct WChannel {
        data_t          data;   // max 64
        strb_t          strb;   // max 8
        bool            last;   // 1
    };

    struct BChannel {
        id_t            id;     // max 16
    };

    struct RChannel {
        data_t          data;   // max 64
        id_t            id;     // max 16
        bool            last;   // 1
    };

private:

    unsigned int addr_width, data_width, id_width, pf_count;

    size_t total_size;
    uint64_t *memblk; // memory blocks, each of 64-bit size

    std::queue<AChannel> a_queue;
    std::queue<WChannel> w_queue;
    std::queue<BChannel> b_queue;
    std::queue<RChannel> r_queue;

    void schedule();

    bool load_state_a(std::istream &stream);
    bool load_state_w(std::istream &stream);
    bool load_state_b(std::istream &stream);
    bool load_state_r(std::istream &stream);

    bool save_state_a(std::ostream &stream);
    bool save_state_w(std::ostream &stream);
    bool save_state_b(std::ostream &stream);
    bool save_state_r(std::ostream &stream);

public:

    bool a_req(const AChannel &payload);
    bool w_req(const WChannel &payload);
    bool b_req(BChannel &payload);
    bool b_ack();
    bool r_req(RChannel &payload);
    bool r_ack();

    bool reset();

    bool load_data(std::istream &stream);
    bool save_data(std::ostream &stream);

    bool load_state(std::istream &stream);
    bool save_state(std::ostream &stream);

    RamModel(unsigned int addr_w, unsigned int data_w, unsigned int id_w, unsigned int pf) :
            addr_width(addr_w), data_width(data_w), id_width(id_w), pf_count(pf)
    {
        total_size = pf_count << 12;
        memblk = new uint64_t[total_size / 8];
        std::memset(memblk, 0, total_size);
    }

    RamModel(const RamModel &) = delete;
    RamModel(RamModel &&) = default;

    RamModel &operator=(const RamModel &) = delete;
    RamModel &operator=(RamModel &&) = default;

    ~RamModel() { delete[] memblk; }

};

};

#endif // #ifndef _RAMMODEL_H_
