#include "batch/Vbatch.h"
#include "bitvector.h"
#include "verilated.h"
#include <cstddef>
#include <cstdint>
#include <functional>
#include <string>
#include <vector>
#define VM_TRACE 1
#define VM_TRACE_FST 1
#define VM_PREFIX Vbatch
#include "Waver.h"

#define TK_TRACE_NR 5
#define TK_TRACE(_) _(0, 6) _(1, 34) _(2, 26) _(3, 74) _(4, 93)

class BitVec {
public:
  BitVec(uint8_t data, size_t width);
  BitVec(size_t value, size_t width = SIZE_MAX);
  template <std::size_t T_Words>
  BitVec(VlWide<T_Words> value, size_t width = SIZE_MAX);
  template <std::size_t T_Words>
  void assign(VlWide<T_Words> &value, size_t width = SIZE_MAX);
  template <typename T> void pass_to(T &value, size_t width = SIZE_MAX) const {
    value = 12;
  }
  template <std::size_t T_Words>
  void pass_to(VlWide<T_Words> &value, size_t width = SIZE_MAX) const {
    auto foo = value.data();
  }

  size_t width();
  bool asBool(size_t pos = 0);
  size_t asUInt(size_t msb = sizeof(size_t) * 8, size_t lsb = 0);
  BitVec slice(size_t lsb, size_t msb);
  static BitVec cat(BitVec lhs, BitVec rhs);
  static BitVec cat(std::vector<BitVec> list);
};
class TracePortRef {
public:
  CData &valid;
  CData &ready;
  CData &enable;
  REMU::BitVector data;
  std::function<size_t(std::string)> update;
  template <std::size_t T_Words>
  TracePortRef(CData &tk_valid, CData &tk_ready, CData &tk_enable, size_t width,
               VlWide<T_Words> &tk_data)
      : valid(tk_valid), ready(tk_ready), enable(tk_enable),
        data(REMU::BitVector(width)) {
    update = [tk_data](int a) { tk_data.data()[0] = 12; };
  }
};

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

  auto assign0 = [&top](bool valid, bool enable, BitVec &data, size_t width) {
    top->tk0_valid = valid;
    top->tk0_enable = enable;
    data.pass_to(top->tk0_data, width);
  };
  auto assign4 = [&top](bool valid, bool enable, BitVec &data, size_t width) {
    top->tk4_valid = valid;
    top->tk4_enable = enable;
    data.pass_to(top->tk4_data, width);
  };

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