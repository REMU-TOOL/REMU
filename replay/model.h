#ifndef _RAMMODEL_H_
#define _RAMMODEL_H_

#include <queue>
#include <iostream>
#include <cstdint>
#include <cstring>

#include "bitvector.h"
#include "circuit.h"

namespace REMU {

void load_fifo(std::queue<BitVector> &fifo, CircuitState &circuit, const CircuitPath &path);
void load_ready_valid_fifo(std::queue<BitVector> &fifo, CircuitState &circuit, const CircuitPath &path);

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

    unsigned int addr_width, data_width, id_width;
    uint64_t mem_size;

    BitVector data;

    std::queue<AChannel> a_queue;
    std::queue<WChannel> w_queue;
    std::vector<std::queue<BChannel>> b_queue;
    std::vector<std::queue<RChannel>> r_queue;

    void schedule();

public:

    bool a_push(const AChannel &payload);
    bool w_push(const WChannel &payload);
    bool b_front(uint16_t id, BChannel &payload);
    bool b_pop(uint16_t id);
    bool r_front(uint16_t id, RChannel &payload);
    bool r_pop(uint16_t id);

    bool reset();

    bool load_data(std::istream &stream);
    void load_state(CircuitState &circuit, const CircuitPath &path);

    RamModel(unsigned int addr_width, unsigned int data_width, unsigned int id_width, uint64_t mem_size);

};

};

#endif // #ifndef _RAMMODEL_H_
