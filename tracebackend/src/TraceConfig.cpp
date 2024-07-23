#include "TraceBackend/Top.hpp"
#include "TraceBackend/utils.hpp"

using fmt::format;
using std::string;
using std::vector;
using utils::mkString;

string TraceConfig::emitCHeader() {
  auto tk_trace_nr = format("#define TK_TRACE_NR {}\n", tracePortsWidth.size());
  auto port_infos = vector<string>();
  for (size_t i = 0; i < tracePortsWidth.size(); i++) {
    port_infos.push_back(format("_({}, {})", i, tracePortsWidth[i]));
  }
  auto foreach_trace_port =
      mkString(port_infos, " ", "#define FOR_EACH_TRACE_PORT(_) ", "\n");
  auto axi_data_width = format("#define AXI_DATA_WIDTH {}\n", AXI4DataWidth);
  return tk_trace_nr + foreach_trace_port + axi_data_width;
}