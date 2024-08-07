#ifndef __TRACE_PORT_RRF_HPP__
#define __TRACE_PORT_RRF_HPP__

#include "bitvector.h"
#include "verilated.h"
#include <cstdint>
#include <fmt/core.h>
#include <functional>

#ifndef __TRACE_PORT_MACRO_HPP__
#define TK_TRACE_NR 3
#define FOR_EACH_TRACE_PORT(_) _(0, 6) _(1, 34) _(2, 26)
#define TK_TRACE_OUT_WIDTH 192
#define AXI_DATA_WIDTH 64
#endif

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

  void calculate_outputs(std::vector<uint8_t> &ret) {
    /* mark info byte */
    ret.push_back(128);
    /* mark data byte */
    for (size_t i = 0; i < 8; i++)
      ret.push_back(0);

    for (size_t i = 0; i < arr.size(); i++) {
      /* skip disable port */
      if (!arr[i].var_enable)
        continue;
      /* info byte */
      ret.push_back(i);
      /* data byte */
      for (size_t byte = 0; byte < arr[i].var_data.n_bytes(); byte++)
        ret.push_back(((uint8_t *)arr[i].var_data.to_ptr())[byte]);
    }

    /* align for AXI4 */
    size_t empty_bytes = AXI_DATA_WIDTH / 8 - (ret.size() % AXI_DATA_WIDTH / 8);
    for (size_t i = 0; i < empty_bytes; i++)
      ret.push_back(0);
  }

  void calculate_outputs(const std::function<void(uint8_t)> &push) {
    size_t cnt = 0;
    /* mark info byte */
    push(128);
    cnt++;
    /* mark data byte */
    for (size_t i = 0; i < 8; i++)
      push(0);
    cnt += 8;

    for (size_t i = 0; i < arr.size(); i++) {
      /* skip disable port */
      if (!arr[i].var_enable)
        continue;
      /* info byte */
      push(i);
      cnt++;
      /* data byte */
      for (size_t byte = 0; byte < arr[i].var_data.n_bytes(); byte++)
        push(((uint8_t *)arr[i].var_data.to_ptr())[byte]);
      cnt += arr[i].var_data.n_bytes();
    }

    /* align for AXI4 */
    size_t empty_bytes = AXI_DATA_WIDTH / 8 - (cnt % AXI_DATA_WIDTH / 8);
    for (size_t i = 0; i < empty_bytes; i++)
      push(0);
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