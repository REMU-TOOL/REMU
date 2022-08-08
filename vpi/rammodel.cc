#include "rammodel.h"

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

bool RamModel::save_data(std::ostream &stream) {
    stream.write(reinterpret_cast<char *>(array.to_ptr()), array_width / 8 * array_depth);
    return !stream.fail();
}

bool RamModel::load_state_a(std::istream &stream) {
    uint32_t count;
    stream.read(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        AChannel payload = {
            .id     = uint16_t((data >> 16) & ((1 << 16) - 1)),
            .len    = uint8_t((data >>  8) & ((1 <<  8) - 1)),
            .size   = uint8_t((data >>  5) & ((1 <<  3) - 1)),
            .burst  = uint8_t((data >>  3) & ((1 <<  2) - 1)),
            .write  = (data & 1) != 0
        };

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.addr = data;

        if (addr_width > 32) {
            stream.read(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;

            payload.addr |= (uint64_t)data << 32;
        }

        a_queue.push(payload);
    }

    return true;
}

bool RamModel::load_state_w(std::istream &stream) {
    uint32_t count;
    stream.read(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        WChannel payload = {
            .data   = BitVector(data_width),
            .strb   = BitVector(data_width / 8, (data >> 16) & ((1 <<  8) - 1)),
            .last   = (data & 1) != 0
        };

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.data.setValue(0, 32, data);

        if (data_width > 32) {
            stream.read(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;

            payload.data.setValue(32, 32, data);
        }

        w_queue.push(payload);
    }

    return true;
}

bool RamModel::load_state_b(std::istream &stream) {
    uint32_t count;
    stream.read(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        BChannel payload = {
            .id = uint16_t((data >> 16) & ((1 << 16) - 1))
        };

        b_queue.push(payload);
    }

    return true;
}

bool RamModel::load_state_r(std::istream &stream) {
    uint32_t count;
    stream.read(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        RChannel payload = {
            .data   = BitVector(data_width),
            .id     = uint16_t((data >> 16) & ((1 << 16) - 1)),
            .last   = (data & 1) != 0
        };

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.data.setValue(0, 32, data);

        if (data_width > 32) {
            stream.read(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;

            payload.data.setValue(32, 32, data);
        }

        r_queue.push(payload);
    }

    return true;
}

bool RamModel::save_state_a(std::ostream &stream) {
    uint32_t count = a_queue.size();
    stream.write(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        const AChannel &payload = a_queue.front();
        uint32_t data = 0;

        data |= (payload.id     & ((1 << 16) - 1)) << 16;
        data |= (payload.len    & ((1 <<  8) - 1)) <<  8;
        data |= (payload.size   & ((1 <<  3) - 1)) <<  5;
        data |= (payload.burst  & ((1 <<  2) - 1)) <<  3;
        if (payload.write)
            data |= 1;

        stream.write(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        data = payload.addr;

        stream.write(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        if (addr_width > 32) {
            data = payload.addr >> 32;

            stream.write(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;
        }

        a_queue.pop();
    }

    return true;
}

bool RamModel::save_state_w(std::ostream &stream) {
    uint32_t count = w_queue.size();
    stream.write(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        const WChannel &payload = w_queue.front();
        uint32_t data = 0;

        data |= (payload.strb & ((1 <<  8) - 1)) << 16;
        if (payload.last)
            data |= 1;

        stream.write(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        data = payload.data;

        stream.write(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        if (addr_width > 32) {
            data = payload.data >> 32;

            stream.write(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;
        }

        w_queue.pop();
    }

    return true;
}

bool RamModel::save_state_b(std::ostream &stream) {
    uint32_t count = b_queue.size();
    stream.write(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        const BChannel &payload = b_queue.front();
        uint32_t data = 0;

        data |= (payload.id & ((1 << 16) - 1)) << 16;

        stream.write(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        b_queue.pop();
    }

    return true;
}

bool RamModel::save_state_r(std::ostream &stream) {
    uint32_t count = r_queue.size();
    stream.write(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        const RChannel &payload = r_queue.front();
        uint32_t data = 0;

        data |= (payload.id & ((1 << 16) - 1)) << 16;
        if (payload.last)
            data |= 1;

        stream.write(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        data = payload.data;

        stream.write(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        if (addr_width > 32) {
            data = payload.data >> 32;

            stream.write(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;
        }

        r_queue.pop();
    }

    return true;
}

bool RamModel::load_state(std::istream &stream) {
    return  load_state_a(stream) &&
            load_state_w(stream) &&
            load_state_b(stream) &&
            load_state_r(stream);
}

bool RamModel::save_state(std::ostream &stream) {
    return  save_state_a(stream) &&
            save_state_w(stream) &&
            save_state_b(stream) &&
            save_state_r(stream);
}
