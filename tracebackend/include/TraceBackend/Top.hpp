#ifndef __TRACE_BACKEND_HPP__
#define __TRACE_BACKEND_HPP__

#include <cstddef>
#include <string>
#include <vector>

class TraceConfig {
public:
  std::vector<size_t> tracePortsWidth;
  size_t AXI4DataWidth;
  size_t endInfoValue;
  size_t endDataWidth;
  size_t infoBytes;
  TraceConfig(std::vector<size_t> tracePortsWidth)
      : tracePortsWidth(tracePortsWidth) {
    AXI4DataWidth = 64;
    endInfoValue = 128;
    endDataWidth = 64;
    infoBytes = 1;
  }
  virtual std::string emitVerilog() = 0;
};

class TraceBackend : public TraceConfig {
public:
  std::string emitVerilog() override;
  TraceBackend(std::vector<size_t> tracePortsWidth)
      : TraceConfig(tracePortsWidth) {}
  TraceBackend(const TraceConfig *that) : TraceConfig(*that) {}
};

class TraceBatch : public TraceConfig {
public:
  std::string emitVerilog() override;
  TraceBatch(std::vector<size_t> tracePortsWidth)
      : TraceConfig(tracePortsWidth) {}
  TraceBatch(const TraceConfig *that) : TraceConfig(*that) {}
};

#endif // __TRACE_BATCH_HPP__