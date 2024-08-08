#ifndef __TRACE_PORT_RRF_HPP__
#define __TRACE_PORT_RRF_HPP__

#include "TraceBackend/utils.hpp"
#include "bitvector.h"
#include "verilated.h"
#include <cstdint>
#include <fmt/core.h>
#include <functional>
#include <queue>

#ifndef __TRACE_PORT_MACRO_HPP__
#define TK_TRACE_NR 3
#define FOR_EACH_TRACE_PORT(_) _(0, 6) _(1, 34) _(2, 26)
#define TK_TRACE_OUT_WIDTH 192
#define TK_TRACE_ALIGN_WIDTH 64
#endif

#define TK_TRACE_ALIGN_NBYTE (TK_TRACE_ALIGN_WIDTH / 8)
class TracePortRef {
public:
  CData &ref_valid;
  CData &ref_ready;
  CData &ref_enable;
  REMU::BitVector var_data;
  std::function<void()> assign_data;
  bool var_enable;

  template <std::size_t T_Words>
  TracePortRef(CData &tk_valid, CData &tk_ready, CData &tk_enable, size_t width,
               VlWide<T_Words> &tk_data)
      : ref_valid(tk_valid), ref_ready(tk_ready), ref_enable(tk_enable),
        var_data(REMU::BitVector(width)) {
    assign_data = [&tk_data, this]() {
      var_data.getValue(0, var_data.width(), (uint64_t *)tk_data.data());
    };
  }
  template <typename T>
  TracePortRef(CData &tk_valid, CData &tk_ready, CData &tk_enable, size_t width,
               T &tk_data)
      : ref_valid(tk_valid), ref_ready(tk_ready), ref_enable(tk_enable),
        var_data(REMU::BitVector(width)) {
    assign_data = [&tk_data, this]() { tk_data = var_data; };
  }
  void poke() {
    ref_enable = var_enable;
    assign_data();
  }
};

class TracePortArr {
public:
  std::array<TracePortRef, TK_TRACE_NR> &arr;
  TracePortArr(std::array<TracePortRef, TK_TRACE_NR> &inputs_ports_arrs)
      : arr(inputs_ports_arrs) {}
  void foreach (const std::function<void(TracePortRef, size_t)> &func) {
    for (size_t i = 0; i < TK_TRACE_NR; i++) {
      func(arr[i], i);
    }
  }
  template <typename T>
  void map(const std::function<T(TracePortRef, size_t)> &func,
           std::vector<T> &ret) {
    for (size_t i = 0; i < TK_TRACE_NR; i++) {
      ret.push_back(func(arr[i], i));
    }
  }

  void generate_inputs() {
    for (size_t i = 0; i < TK_TRACE_NR; i++) {
      arr[i].var_data.rand();
      arr[i].var_enable = REMU::BitVectorUtils::uint8_rand() % 10 > 7;
    }
  }

  void print_inputs() {
    for (size_t i = 0; i < TK_TRACE_NR; i++) {
      if (arr[i].var_enable)
        fmt::print("{} = {}, ", i, arr[i].var_data.hex());
    }
    fmt::print("\n");
  }

  void poke() {
    for (size_t i = 0; i < TK_TRACE_NR; i++) {
      arr[i].poke();
    }
  }

  void calculate_outputs(const std::function<void(uint8_t)> &push) {
    uint16_t pack_len = 8;
    std::queue<uint8_t> data_buf;
    for (size_t i = 0; i < arr.size(); i++) {
      /* skip disable port */
      if (!arr[i].var_enable)
        continue;
      /* info byte */
      data_buf.push(i);
      pack_len++;
      /* data byte */
      for (size_t byte = 0; byte < arr[i].var_data.n_bytes(); byte++)
        data_buf.push(((uint8_t *)arr[i].var_data.to_ptr())[byte]);
      pack_len += arr[i].var_data.n_bytes();
    }

    uint16_t align_len = utils::intCeil(pack_len, TK_TRACE_ALIGN_NBYTE);

    /* mark info byte */
    push(128);

    /* reserve */
    push(0);

    /* length */
    push(align_len & 0xff);
    push(align_len >> 8);

    /* clock delta */
    for (size_t i = 0; i < 4; i++)
      push(0);

    /* pack data */
    while (!data_buf.empty()) {
      push(data_buf.front());
      data_buf.pop();
    }

    /* align */
    for (size_t i = 0; i < align_len - pack_len; i++)
      push(0);
    // fmt::print("\ngenerate {} bytes outputs\n", align_len);
  }

  bool all_fire() {
    auto fire = true;
    for (const auto &port : arr) {
      fire &= port.ref_valid && port.ref_ready;
    }
    return fire;
  }
  bool has_enable() {
    auto enable = false;
    for (const auto &port : arr) {
      enable |= port.ref_enable;
    }
    return enable;
  }
  bool are_valid() {
    auto valid = arr[0].ref_valid;
    for (const auto &port : arr) {
      assert(port.ref_valid == valid);
    }
    return valid;
  }
  bool next_valid() {
    auto valid = REMU::BitVectorUtils::uint8_rand() % 2;
    for (const auto &port : arr) {
      port.ref_valid = valid;
    }
    return valid;
  }
};

#endif