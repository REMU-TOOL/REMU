#include "include/TraceBase.hpp"
#include "TraceBackend/utils.hpp"
#include <fmt/core.h>
#include <string>
#include <vector>

using fmt::format;
using std::string;
using std::vector;
using utils::mkString;

string BaseImpl::emitCHeader() {
  const auto *ifndef = R"(
#ifndef __TRACE_PORT_MACRO_HPP__
#define __TRACE_PORT_MACRO_HPP__
)";

  const auto *endif = "#endif // __TRACE_PORT_MACRO_HPP__";
  auto tk_trace_nr = format("#define TK_TRACE_NR {}\n", portWidth.size());
  auto port_infos = vector<string>();
  for (size_t i = 0; i < portWidth.size(); i++) {
    port_infos.push_back(format("_({}, {})", i, portWidth[i]));
  }
  auto foreach_trace_port =
      mkString(port_infos, " ", "#define FOR_EACH_TRACE_PORT(_) ", "\n");
  auto tk_trace_out_width =
      fmt::format("#define TK_TRACE_OUT_WIDTH {}\n", outDataWidth);
  auto axi_data_width = format("#define AXI_DATA_WIDTH {}\n", AXI4DataWidth());
  auto buffer = vector<string>({ifndef, tk_trace_nr, foreach_trace_port,
                                tk_trace_out_width, axi_data_width, endif});
  return mkString(buffer);
}
