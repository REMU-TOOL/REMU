#include "model.h"

#include <cstdio>

using namespace REMU;

bool RamModel::schedule()
{
    if (a_queue.empty())
        return true;

    const AChannel &a = a_queue.front();

    // skip if there are no enough W bursts for write transfer
    if (a.write && w_queue.size() < a.burst_len())
        return true;

    uint64_t start_address = a.addr;
    uint64_t number_bytes = a.burst_size();
    uint64_t burst_length = a.burst_len();

    if (number_bytes > data_width / 8) {
        fprintf(stderr, "rammodel: burst size (%luB) greater than AXI data width (%uB)\n",
            number_bytes, data_width / 8);
        return false;
    }

    if (a.burst == WRAP) {
        do {
            if (burst_length == 2) break;
            if (burst_length == 4) break;
            if (burst_length == 8) break;
            if (burst_length == 16) break;
            fprintf(stderr, "rammodel: invalid burst length %lu for WRAP burst\n", burst_length);
            return false;
        } while(false);
    }
    else if (a.burst != INCR) {
        fprintf(stderr, "rammodel: unsupported burst type %u\n", a.burst);
        return false;
    }

    uint64_t aligned_address = start_address & ~(number_bytes - 1);
    uint64_t wrap_boundary = start_address & ~(number_bytes * burst_length - 1);
    uint64_t container_lower = a.burst == WRAP ? wrap_boundary : aligned_address;
    uint64_t container_upper = container_lower + number_bytes * burst_length;

    uint64_t address = aligned_address;

    for (uint64_t i = 0; i < burst_length; i++) {
        if (address >= mem_size) {
            fprintf(stderr, "rammodel: address 0x%lx out of boundary\n", address);
            return false;
        }

        BitVector word = data.getValue(address * 8, data_width);

        if (a.write) {
            // consume W request & write data to memory
            const WChannel &w = w_queue.front();

            for (int j = 0; j < data_width / 8; j++)
                if (w.strb.getBit(j))
                    word.setValue(j * 8, w.data.getValue(j * 8, 8));

            data.setValue(address * 8, word);
            w_queue.pop();
        }
        else {
            // generate R responses
            RChannel r = {
                .data   = word,
                .id     = a.id,
                .last   = i == a.len
            };
            r_queue.at(a.id).push(r);
        }

        address += number_bytes;
        if (address == container_upper)
            address = container_lower;
    }

    if (a.write) {
        // generate B response
        BChannel b = {
            .id = a.id
        };
        b_queue.at(a.id).push(b);
    }

    a_queue.pop();

    return true;
}

bool RamModel::a_push(const AChannel &payload)
{
    a_queue.push(payload);
    return true;
}

bool RamModel::w_push(const WChannel &payload)
{
    w_queue.push(payload);
    return true;
}

bool RamModel::b_front(uint16_t id, BChannel &payload)
{
    if (!schedule())
        return false;

    if (!b_queue.at(id).empty())
        payload = b_queue.at(id).front();
    else
        payload = {
            .id     = id,
        };

    return true;
}

bool RamModel::b_pop(uint16_t id)
{
    if (b_queue.at(id).empty())
        return false;

    b_queue.at(id).pop();
    return true;
}

bool RamModel::r_front(uint16_t id, RChannel &payload)
{
    if (!schedule())
        return false;

    if (!r_queue.at(id).empty())
        payload = r_queue.at(id).front();
    else
        payload = {
            .data   = BitVector(data_width),
            .id     = id,
            .last   = false
        };

    return true;
}

bool RamModel::r_pop(uint16_t id)
{
    if (r_queue.at(id).empty())
        return false;

    r_queue.at(id).pop();
    return true;
}

bool RamModel::reset()
{
    a_queue = decltype(a_queue)();
    w_queue = decltype(w_queue)();
    b_queue = decltype(b_queue)(1U << id_width);
    r_queue = decltype(r_queue)(1U << id_width);

    return true;
}

bool RamModel::load_data(std::istream &stream)
{
    stream.read(reinterpret_cast<char *>(data.to_ptr()), data.blks());
    return !stream.fail();
}

void RamModel::load_state(CircuitState &circuit, const CircuitPath &path)
{
    unsigned int id_max = 1U << id_width;

    reset();

    /*
    `define AXI4_CUSTOM_A_PAYLOAD(prefix) { \
        prefix``_awrite, \
        prefix``_aaddr, \
        prefix``_aid, \
        prefix``_alen, \
        prefix``_asize, \
        prefix``_aburst }
    */

    std::queue<BitVector> a_issue_q;
    load_ready_valid_fifo(a_issue_q, circuit, path / "a_issue_q");
    while (!a_issue_q.empty()) {
        auto &elem = a_issue_q.front();
        a_issue_q.pop();
        AChannel a;
        a.burst = (uint8_t) elem.getValue(0, 2);
        a.size  = (uint8_t) elem.getValue(2, 3);
        a.len   = (uint8_t) elem.getValue(5, 8);
        a.id    = (uint16_t)elem.getValue(13, id_width);
        a.addr  =           elem.getValue(13 + id_width, addr_width);
        a.write = (bool)    elem.getValue(13 + id_width + addr_width, 1);
        a_queue.push(a);
    }

    /*
    `define AXI4_CUSTOM_W_PAYLOAD(prefix) { \
        prefix``_wdata, \
        prefix``_wstrb, \
        prefix``_wlast }
    */

    std::queue<BitVector> w_issue_q;
    load_ready_valid_fifo(w_issue_q, circuit, path / "w_issue_q");
    while (!w_issue_q.empty()) {
        auto &elem = w_issue_q.front();
        w_issue_q.pop();
        WChannel w;
        w.last  = (bool)    elem.getValue(0, 1);
        w.strb  =           elem.getValue(1, data_width/8);
        w.data  =           elem.getValue(1 + data_width/8, data_width);
        w_queue.push(w);
    }

    /*
    `define AXI4_CUSTOM_B_PAYLOAD(prefix) { \
        prefix``_bid }
    */

    for (unsigned int i = 0; i < id_max; i++) {
        std::queue<BitVector> b_roq;
        std::ostringstream ss;
        ss << "b_roq_genblk[" << i << "].queue";
        load_ready_valid_fifo(b_roq, circuit, path / ss.str());
        auto &queue = b_queue.at(i);
        while (!b_roq.empty()) {
            auto &elem = b_roq.front();
            b_roq.pop();
            BChannel b;
            b.id    = (uint16_t)elem.getValue(0, id_width);
            queue.push(b);
        }
    }

    /*
    `define AXI4_CUSTOM_R_PAYLOAD(prefix) { \
        prefix``_rdata, \
        prefix``_rid, \
        prefix``_rlast }
    */

    for (unsigned int i = 0; i < id_max; i++) {
        std::queue<BitVector> r_roq;
        std::ostringstream ss;
        ss << "r_roq_genblk[" << i << "].queue";
        load_ready_valid_fifo(r_roq, circuit, path / ss.str());
        auto &queue = r_queue.at(i);
        while (!r_roq.empty()) {
            auto &elem = r_roq.front();
            r_roq.pop();
            RChannel r;
            r.last  = (bool)    elem.getValue(0, 1);
            r.id    = (uint16_t)elem.getValue(1, id_width);
            r.data  =           elem.getValue(1 + id_width, data_width);
            queue.push(r);
        }
    }
}

RamModel::RamModel(unsigned int addr_width, unsigned int data_width, unsigned int id_width, uint64_t mem_size) :
    addr_width(addr_width),
    data_width(data_width),
    id_width(id_width),
    mem_size(mem_size),
    data(mem_size * 8)
{
    reset();
}
