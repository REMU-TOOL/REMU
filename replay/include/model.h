#ifndef _RAMMODEL_H_
#define _RAMMODEL_H_

#include <queue>
#include <iostream>
#include <cstdint>
#include <cstring>

#include "bitvector.h"
#include "circuit.h"

namespace Emu {

struct FifoModel {
    std::queue<BitVector> fifo;
    void load(CircuitInfo *circuit);
};

class RamModel {

public:

    static const uint8_t INCR  = 1;
    static const uint8_t WRAP  = 2;

    struct AChannel {
        uint64_t        addr;   // max 64
        uint16_t        id;     // max 16
        uint8_t         len;    // 8
        uint8_t         size;   // 3
        uint8_t         burst;  // 2
        bool            write;  // 1

        inline uint64_t burst_len() const { return len + 1; }
        inline uint64_t burst_size() const { return 1 << size; }
    };

    struct WChannel {
        BitVector       data;   // unlimited
        BitVector       strb;   // unlimited
        bool            last;   // 1
    };

    struct BChannel {
        uint16_t        id;     // max 16
    };

    struct RChannel {
        BitVector       data;   // unlimited
        uint16_t        id;     // max 16
        bool            last;   // 1
    };

private:

    unsigned int addr_width, data_width, id_width, pf_count;

    size_t array_width, array_depth;
    BitVectorArray array;

    std::queue<AChannel> a_queue;
    std::queue<WChannel> w_queue;
    std::queue<BChannel> b_queue;
    std::queue<RChannel> r_queue;

    void schedule();

public:

    bool a_req(const AChannel &payload);
    bool w_req(const WChannel &payload);
    bool b_req(BChannel &payload);
    bool b_ack();
    bool r_req(RChannel &payload);
    bool r_ack();

    bool reset();

    bool load_data(std::istream &stream);
    void load_state(CircuitInfo *circuit);

    RamModel(unsigned int addr_w, unsigned int data_w, unsigned int id_w, unsigned int pf) :
        addr_width(addr_w), data_width(data_w), id_width(id_w), pf_count(pf),
        array_width(data_w > 64 ? data_w : 64), array_depth((pf_count << 12) / (array_width / 8)),
        array(array_width, array_depth) {}

};

};

#endif // #ifndef _RAMMODEL_H_
