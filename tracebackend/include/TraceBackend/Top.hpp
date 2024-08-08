#ifndef __TRACE_BACKEND_HPP__
#define __TRACE_BACKEND_HPP__

#include <cstddef>
#include <string>
#include <vector>

class TraceConfig {
public:
  std::vector<size_t> tracePortsWidth;
  size_t outAlignWidth;
  size_t markInfoValue;
  size_t markDataWidth;
  size_t infoBytes;
  TraceConfig(std::vector<size_t> tracePortsWidth)
      : tracePortsWidth(tracePortsWidth) {
    outAlignWidth = 64;
    markInfoValue = 128;
    markDataWidth = 56;
    infoBytes = 1;
  }
  virtual std::string emitVerilog() = 0;
  virtual std::string emitCHeader() = 0;
};

class TraceBackend : public TraceConfig {
public:
  std::string emitVerilog() override;
  std::string emitCHeader() override;
  TraceBackend(std::vector<size_t> tracePortsWidth)
      : TraceConfig(tracePortsWidth) {}
  TraceBackend(const TraceConfig *that) : TraceConfig(*that) {}
};

class TraceBatch : public TraceConfig {
public:
  std::string emitVerilog() override;
  std::string emitCHeader() override;
  TraceBatch(std::vector<size_t> tracePortsWidth)
      : TraceConfig(tracePortsWidth) {}
  TraceBatch(const TraceConfig *that) : TraceConfig(*that) {}
};

#endif // __TRACE_BATCH_HPP__