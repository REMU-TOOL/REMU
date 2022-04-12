#include "rammodel.h"

using namespace Replay;

static inline uint64_t get_bits(uint64_t data, unsigned int offset, unsigned int width) {
    return (data >> offset) & (~1UL >> (64 - width));
}

static inline void set_bits(uint64_t &data, unsigned int offset, unsigned int width, uint64_t new_value) {
    uint64_t mask = (~1UL >> (64 - width)) << offset;
    data = (data & ~mask) | ((new_value << offset) & mask);
}

void RamModel::schedule() {
    if (a_queue.empty())
        return;

    const AChannel &a = a_queue.front();

    if (a.write) {
        // write transfer

        // skip if there are no enough W bursts for write transfer
        if (w_queue.size() < a.burst_len())
            return;

        addr_t addr = a.addr;
        addr_t size = a.burst_size();
        addr &= ~(size - 1); // align start address according to burst size

        // TODO: WRAP

        for (addr_t i = 0; i < a.burst_len(); i++) {
            const WChannel &w = w_queue.front();

            // offset in WDATA
            addr_t offset_mask  = data_width / 8 - 1;
            addr_t offset       = addr & offset_mask;

            // data & write mask
            data_t data = w.data;
            strb_t strb = w.strb & (((1 << size) - 1) << offset);
            data_t mask = 0;
            for (int j = 0; j < 8; j++)
                if (strb & (1 << j))
                    mask |= 0xffUL << (j * 8);

            // offset in block
            addr_t blk_offset   = addr & 7UL;
            addr_t blk_base     = addr & ~7UL;

            // write data to block
            if (blk_base < total_size) {
                data_t &blk_data = memblk[blk_base / 8];
                data <<= (blk_offset - offset) * 8;
                mask <<= (blk_offset - offset) * 8;
                blk_data = (blk_data & ~mask) | (data & mask);
            }

            addr += size;
            w_queue.pop();
        }

        // generate B response
        BChannel b;
        b.id = a.id;
        b_queue.push(b);
    }
    else {
        // read transfer

        addr_t addr = a.addr;
        addr_t size = a.burst_size();
        addr &= ~(size - 1); // align start address according to burst size

        // TODO: WRAP

        for (addr_t i = 0; i < a.burst_len(); i++) {
            // offset in WDATA
            addr_t offset_mask  = data_width / 8 - 1;
            addr_t offset       = addr & offset_mask;

            // offset in block
            addr_t blk_offset   = addr & 7UL;
            addr_t blk_base     = addr & ~7UL;

            // read data block
            data_t data = 0;
            if (blk_base < total_size) {
                data_t blk_data = memblk[blk_base / 8];
                data = blk_data >> ((blk_offset - offset) * 8);
            }

            // generate R response
            RChannel r;
            r.data = data;
            r.id = a.id;
            r.last = i == a.len;
            r_queue.push(r);

            addr += size;
        }
    }

    a_queue.pop();
}

bool RamModel::a_req(const AChannel &payload) {
    if (payload.burst != RamModel::INCR &&
        payload.burst != RamModel::WRAP)
        return false;

    // max data width = 64
    if (payload.size > 3)
        return false;

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
    stream.read(reinterpret_cast<char *>(memblk), total_size);
    return !stream.fail();
}

bool RamModel::save_data(std::ostream &stream) {
    stream.write(reinterpret_cast<char *>(memblk), total_size);
    return !stream.fail();
}

bool RamModel::load_state_a(std::istream &stream) {
    uint32_t count;
    stream.read(reinterpret_cast<char *>(&count), 4);
    if (stream.fail())
        return false;

    while (count--) {
        AChannel payload;
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.id      = (data >> 16) & ((1 << 16) - 1);
        payload.len     = (data >>  8) & ((1 <<  8) - 1);
        payload.size    = (data >>  5) & ((1 <<  3) - 1);
        payload.burst   = (data >>  3) & ((1 <<  2) - 1);
        payload.write   = data & 1;

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
        WChannel payload;
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.strb    = (data >> 16) & ((1 <<  8) - 1);
        payload.last    = data & 1;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.data = data;
        if (data_width > 32) {
            stream.read(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;

            payload.data |= (uint64_t)data << 32;
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
        BChannel payload;
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.id = (data >> 16) & ((1 << 16) - 1);

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
        RChannel payload;
        uint32_t data;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.id      = (data >> 16) & ((1 << 16) - 1);
        payload.last    = data & 1;

        stream.read(reinterpret_cast<char *>(&data), 4);
        if (stream.fail())
            return false;

        payload.data = data;

        if (data_width > 32) {
            stream.read(reinterpret_cast<char *>(&data), 4);
            if (stream.fail())
                return false;

            payload.data |= (uint64_t)data << 32;
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
