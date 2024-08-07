#include "verilated.h"

#define VM_TRACE 1
#define VM_TRACE_FST 1
#define VM_PREFIX Vtop

#include "design/Backend/TracePortMacro.h"
#include "design/Backend/Vtop.h"

/* Ref include must be after Macro include */
#include "include/TracePortRef.hpp"
#include "include/axi4ref.hpp"

#include "Waver.h"
#include <array>

using std::vector;

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
  std::array<TracePortRef, TK_TRACE_NR> inputs_port_arr = {
      FOR_EACH_TRACE_PORT(PORT_DEF)};
  auto trace_port_arr = TracePortArr(inputs_port_arr);
#undef PORT_DEF

  auto axi_deleg = AXI4::SlaveWriteModule(36, AXI_DATA_WIDTH, 4);

  auto axi =
      AXI4SlaveRef<4, decltype(top->m_axi_wdata), decltype(top->m_axi_awaddr)>(
          top->m_axi_awid, top->m_axi_awlen, top->m_axi_awsize,
          top->m_axi_awburst, top->m_axi_awlock, top->m_axi_awcache,
          top->m_axi_awprot, top->m_axi_awqos, top->m_axi_awregion,
          top->m_axi_awuser, top->m_axi_awvalid, top->m_axi_awready,
          top->m_axi_awaddr, top->m_axi_wstrb, top->m_axi_wlast,
          top->m_axi_wuser, top->m_axi_wvalid, top->m_axi_wready,
          top->m_axi_wdata, top->m_axi_bid, top->m_axi_bresp, top->m_axi_buser,
          top->m_axi_bvalid, top->m_axi_bready, axi_deleg);

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

  auto expected_data = std::queue<uint8_t>();
  AXI4::addr_t expected_addr = 0x10000000;

  axi_deleg.visitor = [&expected_data, &expected_addr,
                       &context](AXI4::BRecord &brecord) {
    auto dut = std::vector<uint8_t>();

    auto nbytes = brecord.to_vec(dut, expected_addr);
    bool cmp_res = true;
    for (size_t i = 0; i < nbytes; i++) {
      cmp_res &= expected_data.front() == dut[i];
    }
    if (nbytes <= 0 || cmp_res != 0) {
      context->gotFinish(true);
    }
    expected_addr += nbytes;
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
    axi.update_outputs();
  };

  auto check_outputs = [&]() {
    if (trace_port_arr.all_fire()) {
      fmt::print("[{}] inputs fire {}: ", context->time(), in_fire_cnt++);
      trace_port_arr.print_inputs();
      if (trace_port_arr.has_enable()) {
        trace_port_arr.calculate_outputs(
            [&expected_data](uint8_t x) { expected_data.push(x); });
      }
      axi.check_inputs();
    }
  };

  while (!context->gotFinish() && duration >= context->time()) {
    // posedge
    context->timeInc(1);
    top->host_clk = !top->host_clk;
    top->eval();
    waver.dump();

    // negedge
    context->timeInc(1);
    set_inputs();
    top->host_clk = !top->host_clk;
    top->eval();
    waver.dump();
    check_outputs();
  }

  printf("quit sim with total %lu cycle num\n", context->time());
  top->final();
  return 0;
}