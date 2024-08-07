#include <cassert>
#include <cstdio>
#include <cstdlib>
#define VM_TRACE 1
#define VM_TRACE_FST 1
#define VM_PREFIX Vtop
#include "bitvector.h"
#include "design/Batch/TracePortMacro.h"
#include "design/Batch/Vtop.h"

#include "include/TracePortRef.hpp"

#include "Waver.h"
#include <array>
#include <cstdint>
#include <fmt/core.h>
#include <queue>
#include <vector>

using REMU::BitVector;
using REMU::BitVectorUtils::uint8_rand;
using std::array;
using std::string;

int main(int argc, char *argv[]) {
  /* should not be unique_ptr, becasue pass to lambda */
  auto *context = new VerilatedContext();

  context->commandArgs(argc, argv);

  auto get_plus_arg = [context](const std::string &prefix) {
    /* must copy, becasue func reture a global static point */
    std::string tmp = context->commandArgsPlusMatch(prefix.c_str());
    /* tmp is "+foo=bar", to skip "+", must add 1 */
    return tmp.substr(prefix.size() + 1);
  };

  std::string wave_file = get_plus_arg("dumpfile=");
  auto duration_int = atol(get_plus_arg("duration=").c_str());
  size_t duration = duration_int <= 0 ? ~0 : duration_int;
  printf("dump wave file to %s, with duration %lu\n", wave_file.c_str(),
         duration);

  /* second param must be  "", could remove TOP. prefix in scope */
  auto top = std::make_unique<VM_PREFIX>(context, "");

#define PORT_DEF(index, portWidth)                                             \
  TracePortRef(top->tk##index##_valid, top->tk##index##_ready,                 \
               top->tk##index##_enable, portWidth, top->tk##index##_data),
  array<TracePortRef, TK_TRACE_NR> inputs_port_arr = {
      FOR_EACH_TRACE_PORT(PORT_DEF)};
  auto trace_port_arr = TracePortArr(inputs_port_arr);
#undef PORT_DEF

  auto waver = Waver(true, top.get(), wave_file);
  top->host_clk = false;
  top->host_rst = false;

  // reset state
  while (!context->gotFinish() && context->time() < 32) {
    context->timeInc(1);
    top->host_clk = !top->host_clk;
    top->eval();
    waver.dump();
  }
  top->host_rst = true;

  auto expected = std::queue<std::vector<uint8_t>>();

  auto checkodata = [&]() {
    // const auto *dut = (uint8_t *)top->odata.data();
    // auto dut_vec = BitVector(TK_TRACE_OUT_WIDTH);
    // dut_vec.setValue(0, TK_TRACE_OUT_WIDTH, (uint64_t *)dut);
    // fmt::print("[{}] top.odata = {}\n", context->time(), dut_vec.hex());
  };
  size_t in_fire_cnt = 0;
  size_t out_fire_cnt = 0;
  auto set_inputs = [&]() {
    if (trace_port_arr.all_fire() || !trace_port_arr.are_valid()) {
      if (trace_port_arr.next_valid()) {
        trace_port_arr.generate_inputs();
        trace_port_arr.poke();
      }
    }
    top->oready = uint8_rand() % 2;
  };
  auto check_outputs = [&]() {
    if (trace_port_arr.all_fire()) {
      fmt::print("[{}] inputs fire {}: ", context->time(), in_fire_cnt++);
      trace_port_arr.print_inputs();
      if (trace_port_arr.has_enable()) {
        trace_port_arr.calculate_outputs(expected.emplace());
      }
    }
    if (top->ovalid && top->oready) {
      fmt::print("[{}] output fire {}: ", context->time(), out_fire_cnt++);
      const auto &ref = expected.front();
      const auto *dut = (uint8_t *)top->odata.data();
      auto cmp = memcmp(ref.data(), dut, top->olen);
      assert(ref.size() <= TK_TRACE_OUT_WIDTH / 8);
      if (cmp != 0) {
        fmt::print("error !!!\n", context->time());
        auto ref_vec = BitVector(TK_TRACE_OUT_WIDTH);
        auto dut_vec = BitVector(TK_TRACE_OUT_WIDTH);
        ref_vec.setValue(0, TK_TRACE_OUT_WIDTH, (uint64_t *)ref.data());
        dut_vec.setValue(0, TK_TRACE_OUT_WIDTH, (uint64_t *)dut);
        fmt::print("dut = {}\n", dut_vec.hex());
        fmt::print("ref = {}\n", ref_vec.hex());
        context->gotFinish(true);
      }
      fmt::print("pass !!!\n");
      expected.pop();
    }
  };

  while (!context->gotFinish() && duration >= context->time()) {
    // posedge
    context->timeInc(1);
    top->host_clk = !top->host_clk;
    top->eval();
    waver.dump();
    checkodata();

    // negedge
    context->timeInc(1);
    set_inputs();
    top->host_clk = !top->host_clk;
    top->eval();
    waver.dump();
    checkodata();
    check_outputs();
  }
  printf("quit sim with total %lu cycle num\n", context->time());
  top->final();
  return 0;
}
