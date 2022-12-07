#include "model.h"

#include <stdexcept>
#include <sstream>

using namespace Replay;

void RamModel::schedule() {
    if (a_queue.empty())
        return;

    const AChannel &a = a_queue.front();

    // skip if there are no enough W bursts for write transfer
    if (a.write && w_queue.size() < a.burst_len())
        return;

    uint64_t start_address = a.addr;
    uint64_t number_bytes = a.burst_size();
    uint64_t burst_length = a.burst_len();

    if (number_bytes > array_width / 8) {
        throw std::invalid_argument("burst size greater than AXI data width");
    }

    if (a.burst == WRAP) {
        do {
            if (burst_length == 2) break;
            if (burst_length == 4) break;
            if (burst_length == 8) break;
            if (burst_length == 16) break;
            throw std::invalid_argument("invalid burst length for WRAP burst");
        } while(false);
    }
    else if (a.burst != INCR) {
        throw std::invalid_argument("unsupported burst type " + std::to_string(a.burst));
    }

    uint64_t aligned_address = start_address & ~(number_bytes - 1);
    uint64_t wrap_boundary = start_address & ~(number_bytes * burst_length - 1);
    uint64_t container_lower = a.burst == WRAP ? wrap_boundary : aligned_address;
    uint64_t container_upper = container_lower + number_bytes * burst_length;

    uint64_t address = aligned_address;

    for (uint64_t i = 0; i < burst_length; i++) {
        if (address >= (uint64_t(pf_count) << 12)) {
            std::ostringstream ss;
            ss << "address 0x" << std::hex << address << " out of boundary";
            throw std::invalid_argument(ss.str());
        }

        uint64_t index = address / (array_width / 8);
        BitVector word = array.get(index);

        if (a.write) {
            // consume W request & write data to memory
            const WChannel &w = w_queue.front();

            for (int j = 0; j < array_width / 8; j++)
                if (w.strb.getBit(j))
                    word.setValue(j * 8, w.data.getValue(j * 8, 8));

            array.set(index, word);
            w_queue.pop();
        }
        else {
            // generate R responses
            RChannel r = {
                .data   = word,
                .id     = a.id,
                .last   = i == a.len
            };
            r_queue.push(r);
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
        b_queue.push(b);
    }

    a_queue.pop();
}

bool RamModel::a_req(const AChannel &payload) {
    a_queue.push(payload);
    return true;
}

bool RamModel::w_req(const WChannel &payload) {
    w_queue.push(payload);
    return true;
}

bool RamModel::b_req(BChannel &payload) {
    schedule();

    if (b_queue.size() == 0)
        return false;

    payload = b_queue.front();
    return true;
}

bool RamModel::b_ack() {
    b_queue.pop();
    return true;
}

bool RamModel::r_req(RChannel &payload) {
    schedule();

    if (r_queue.size() == 0)
        return false;

    payload = r_queue.front();
    return true;
}

bool RamModel::r_ack() {
    r_queue.pop();
    return true;
}

bool RamModel::reset() {
    while (!a_queue.empty()) a_queue.pop();
    while (!w_queue.empty()) w_queue.pop();
    while (!b_queue.empty()) b_queue.pop();
    while (!r_queue.empty()) r_queue.pop();

    return true;
}

bool RamModel::load_data(std::istream &stream) {
    stream.read(reinterpret_cast<char *>(array.to_ptr()), array_width / 8 * array_depth);
    return !stream.fail();
}

void RamModel::load_state(CircuitInfo *circuit)
{
    FifoModel fifo_model;

    /*
    `define AXI4_CUSTOM_A_PAYLOAD(prefix) { \
        prefix``_awrite, \
        prefix``_aaddr, \
        prefix``_aid, \
        prefix``_alen, \
        prefix``_asize, \
        prefix``_aburst }
    */

    fifo_model.load(circuit->cell({"a_fifo"}));
    a_queue = decltype(a_queue)();
    while (!fifo_model.fifo.empty()) {
        auto &elem = fifo_model.fifo.front();
        fifo_model.fifo.pop();
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

    fifo_model.load(circuit->cell({"w_fifo"}));
    w_queue = decltype(w_queue)();
    while (!fifo_model.fifo.empty()) {
        auto &elem = fifo_model.fifo.front();
        fifo_model.fifo.pop();
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

    fifo_model.load(circuit->cell({"b_fifo"}));
    b_queue = decltype(b_queue)();
    while (!fifo_model.fifo.empty()) {
        auto &elem = fifo_model.fifo.front();
        fifo_model.fifo.pop();
        BChannel b;
        b.id    = (uint16_t)elem.getValue(0, id_width),
        b_queue.push(b);
    }

    /*
    `define AXI4_CUSTOM_R_PAYLOAD(prefix) { \
        prefix``_rdata, \
        prefix``_rid, \
        prefix``_rlast }
    */

    fifo_model.load(circuit->cell({"r_fifo"}));
    r_queue = decltype(r_queue)();
    while (!fifo_model.fifo.empty()) {
        auto &elem = fifo_model.fifo.front();
        fifo_model.fifo.pop();
        RChannel r;
        r.last  = (bool)    elem.getValue(0, 1),
        r.id    = (uint16_t)elem.getValue(1, id_width),
        r.data  =           elem.getValue(1 + id_width, data_width),
        r_queue.push(r);
    }
}
