#include "batch/Vbatch.h"
#include "bitvector.h"
#include "verilated.h"
#include <array>
#include <cstdint>
#include <vector>
#define VM_TRACE 1
#define VM_TRACE_FST 1
#define VM_PREFIX Vbatch
#include "Waver.h"

#define TK_TRACE_NR 5
#define FOR_EACH_TRACE_PORT(_) _(0, 6) _(1, 34) _(2, 26) _(3, 74) _(4, 93)
#define AXI_DATA_WIDTH 64

using REMU::BitVector;
using std::array;
using std::string;

class TracePortRef {
public:
  CData &ref_valid;
  CData &ref_ready;
  CData &ref_enable;
  BitVector var_data;
  std::function<void()> assign_data;
  bool var_valid;
  bool var_enable;

  template <std::size_t T_Words>
  TracePortRef(CData &tk_valid, CData &tk_ready, CData &tk_enable, size_t width,
               VlWide<T_Words> &tk_data)
      : ref_valid(tk_valid), ref_ready(tk_ready), ref_enable(tk_enable),
        var_data(BitVector(width)) {
    assign_data = [&tk_data, this]() {
      var_data.getValue(0, var_data.width(), (uint64_t *)tk_data.data());
    };
  }
  template <typename T>
  TracePortRef(CData &tk_valid, CData &tk_ready, CData &tk_enable, size_t width,
               T &tk_data)
      : ref_valid(tk_valid), ref_ready(tk_ready), ref_enable(tk_enable),
        var_data(BitVector(width)) {
    assign_data = [&tk_data, this]() { tk_data = var_data; };
  }
  void poke() {
    ref_valid = var_valid;
    ref_enable = var_enable;
    assign_data();
  }
};

using TracePortArr = array<TracePortRef, TK_TRACE_NR>;

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
  TracePortArr trace_port_arr = {FOR_EACH_TRACE_PORT(PORT_DEF)};
#undef PORT_DEF

  auto waver = Waver(true, top.get(), wave_file);
  top->clk = false;
  top->rst = true;

  while (!context->gotFinish() && duration >= context->time()) {
    top->eval();
    waver.dump();
    context->timeInc(1);
    top->clk = !top->clk;
    top->rst = context->time() < 32;
  }
  printf("quit sim with total %lu cycle num\n", context->time());
  top->final();
  return 0;
}

void generate_inputs(TracePortArr &arr) {
  auto ret = std::array<BitVector, TK_TRACE_NR>();
  for (auto &port : arr) {
    port.var_data.rand();
    port.var_enable = std::rand() % 2;
  }
}

void calculate_outputs(const TracePortArr &arr, std::vector<uint8_t> &ret) {
  ret.clear();
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
  /* end info byte */
  ret.push_back(128);
  /* end data byte */
  for (size_t i = 0; i < 8; i++)
    ret.push_back(0);
  /* align for AXI4 */
  size_t empty_bytes = AXI_DATA_WIDTH - ret.size() % AXI_DATA_WIDTH;
  for (size_t i = 0; i < empty_bytes; i++)
    ret.push_back(0);
}