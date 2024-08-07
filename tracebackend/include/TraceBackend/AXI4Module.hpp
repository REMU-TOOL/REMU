#include "bitvector.h"
#include <cstddef>
#include <cstdint>
#include <fmt/core.h>
#include <functional>
#include <optional>
#include <queue>
#include <sys/types.h>
#include <vector>

namespace AXI4 {

using addr_t = uint64_t;

using burst_t = enum {
  BURST_FIXED = 0,
  BURST_INCR = 1,
  BURST_WRAP = 2,
  BURST_RESERVED = 3
};

using resp_t = enum {
  RESP_OKEY = 0,
  RESP_EXOKEY = 1,
  RESP_SLVERR = 2,
  RESP_DECERR = 3
};

#define AUTO_T(width)                                                          \
  typename std::conditional<                                                   \
      (width) <= 8, CData,                                                     \
      typename std::conditional<                                               \
          (width) <= 16, SData,                                                \
          typename std::conditional<(width) <= 32, IData,                      \
                                    QData>::type>::type>::type

struct AWField {
  addr_t addr;
  uint8_t id;
  burst_t burst;
  uint8_t len;
  uint8_t size;
};

struct WField {
  REMU::BitVector strb;
  std::vector<uint8_t> data;
};

struct BRecord {
  std::vector<WField> w;
  bool has_set_port;
  std::string err_msg;
  bool could_valid() { return true; }
  bool not_set_port() {
    has_set_port = true;
    return !has_set_port;
  }

  addr_t start_addr; // aw.addr
  uint8_t nbytes;    // aw.size << 1
  uint8_t burst_nr;  // aw.len + 1
  uint8_t id;        // aw.id
  burst_t burst_type;

  BRecord(AWField &aw, WField &w) {
    start_addr = aw.addr;
    nbytes = 1 << aw.size;
    burst_nr = aw.len + 1;
    id = aw.id;
    burst_type = aw.burst;
    has_set_port = false;
  }

  bool check_req_legal() {
#define ASSERT(cond, msg)                                                      \
  do {                                                                         \
    if (cond) {                                                                \
    } else {                                                                   \
      err_msg = msg;                                                           \
      return false;                                                            \
    }                                                                          \
  } while (0)

    addr_t align_addr = start_addr & ~(nbytes - 1);
    bool aligned = start_addr == align_addr;

    if (burst_type == BURST_WRAP) {
      ASSERT(aligned, "Arburst type is WRAP but not aligned");
      ASSERT(burst_nr == 2 || burst_nr == 4 || burst_nr == 8 || burst_nr == 16,
             "burst type is WRAP but arlen is");
      // NOTE:wrap type must not cross 4KB bound for wrapping at 4KB
    } else {
      ASSERT(align_addr >> 12 ==
                 (align_addr + ((addr_t)nbytes * burst_nr - 1)) >> 12,
             fmt::format("burst type is %d but cross 4KB address bound {}",
                         burst_type));
      if (burst_nr) {
        ASSERT(aligned, "This enviroment do not support unalign burst");
      }
    } // NOTE: FIX must not cross 4KB address bound
    return true;
#undef ASSERT
  }

  ssize_t to_vec(std::vector<uint8_t> &mem, addr_t base_addr) {
#define ASSERT(cond, msg)                                                      \
  do {                                                                         \
    if (cond) {                                                                \
    } else {                                                                   \
      err_msg = msg;                                                           \
      return -1;                                                               \
    }                                                                          \
  } while (0)

    ASSERT(burst_type != BURST_FIXED, "burst type fix can not to mem");

    size_t total_cap = start_addr + ((size_t)burst_type * nbytes) - base_addr;
    if (mem.capacity() < total_cap) {
      mem.resize(total_cap);
    }

    addr_t wrap_off_mask = (burst_nr * nbytes) - 1;
    addr_t wrap_bound = start_addr & ~wrap_off_mask;
    addr_t strb_mask = w[0].data.size() - 1;
    for (size_t i = 0; i < burst_nr; i++) {
      addr_t logic_addr =
          (start_addr + i * nbytes) & wrap_off_mask | wrap_bound;
      uint8_t *dest = mem.data() + (logic_addr - base_addr);
      size_t src_offset = ((start_addr + i * nbytes) & strb_mask);
      uint8_t *src = w[i].data.data() + src_offset;
      if (w[i].strb >> src_offset == (1 << nbytes) - 1)
        memcpy(dest, src, nbytes);
      else {
        for (size_t j = 0; j < nbytes; j++) {
          if (w[i].strb.getBit(src_offset + j)) {
            dest[j] = src[j];
          }
        }
      }
    }
    return (ssize_t)burst_nr * nbytes;
#undef ASSERT
  }
};

// bitvector module
class SlaveWriteModule {
public:
  size_t addr_width;
  size_t data_width;
  size_t id_width;
  size_t user_width;

  std::queue<AWField> aw_queue;

  std::vector<WField> w_curr_hs;
  std::queue<std::vector<WField>> w_queue;

  std::queue<BRecord> b_queue;

  struct {
    std::optional<bool> awready;

    std::optional<bool> wready;

    struct BPort {
      bool valid;
      uint8_t id;
      resp_t resp;
      REMU::BitVector user;
      BPort(const BRecord &brecord);
      BPort() : valid(false){};
    };

    std::optional<BPort> b;
  } next_state;

  SlaveWriteModule(size_t addr_width, size_t data_width, size_t id_width,
                   size_t user_width = 0)
      : addr_width(user_width), data_width(id_width), id_width(data_width),
        user_width(addr_width) {}

  void schedule() {
    while (!aw_queue.empty() && !w_queue.empty()) {
      b_queue.emplace(aw_queue.front(), w_queue.front(), false);
      aw_queue.pop();
      w_queue.pop();
    }
  }

  void aw_fire_cb(uint64_t addr, uint8_t id, uint8_t burst, uint8_t len,
                  uint8_t size) {
    aw_queue.emplace(addr, id, burst, len, size);
    schedule();
  }

  void w_fire_cb(uint8_t *strb, bool last, uint8_t *data) {
    auto data_vec = std::vector<uint8_t>(data, data + data_width);
    auto strb_vec = REMU::BitVector();
    strb_vec.setValue(0, data_width / 8, (uint64_t *)strb);
    w_curr_hs.emplace_back(data_vec, strb_vec);
    if (last) {
      w_queue.emplace(w_curr_hs);
      w_curr_hs.clear();
      schedule();
    }
  }
  // try to check and pop
  void b_fire_cb() {
    visitor(b_queue.front());
    next_state.b.emplace();
    b_queue.pop();
  }

  void tick_cb() {
    if (!b_queue.empty()) {
      auto bhead = b_queue.front();
      if (bhead.could_valid() && bhead.not_set_port()) {
        next_state.b.emplace(bhead);
      }
    }
  }

  std::function<void(BRecord &record)> visitor;
};

} // namespace AXI4