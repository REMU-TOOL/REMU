#ifndef __WAVER_H__
#define __WAVER_H__

/** when editor this file under clangd
 * define blow macro to enable lsp
 * but do not define this macro when compile
 */
// #define VM_TRACE 1
// #define VM_PREFIX Vemu_elab
// #include "Vemu_elab.h"

#include "verilated.h"
#include <memory>

#ifndef VM_TRACE_FST
// emulate new verilator behavior for legacy versions
#define VM_TRACE_FST 0
#endif

#if VM_TRACE
#if VM_TRACE_FST
#define vltwave_t VerilatedFstC
#define vltwave_fmt "fst"
#include <verilated_fst_c.h>
#else
#define vltwave_t VerilatedVcdC
#define vltwave_fmt "vcd"
#include <verilated_vcd_c.h>
#endif
#endif

class Waver {
public:
  bool traceOn;
#if VM_TRACE
  std::unique_ptr<vltwave_t> tfp;
  VerilatedContext *contextp;
#endif

  Waver(bool enable, VM_PREFIX *top, const std::string wave_name)
      : traceOn(enable) {
#if VM_TRACE
    tfp = std::make_unique<vltwave_t>();
    std::string traceFile = wave_name;
    contextp = top->contextp();

    if (traceOn) {
      contextp->traceEverOn(true);
      top->trace(tfp.get(), 99);
      tfp->open(traceFile.c_str());
    }
#endif
  }
  void dump() {
#if VM_TRACE
    if (traceOn) {
      tfp->dump(contextp->time());
    }
#endif
  }
  ~Waver() {
#if VM_TRACE
    if (traceOn) {
      tfp->close();
    }
#endif
  }
};
#endif