#include "TraceBackend/Top.hpp"
#include "include/TraceBase.hpp"

using std::string;

class TraceBackendImpl : public BaseImpl {
public:
  string moduleName = "TraceBackend";

  string tracePortInstance() {
    return formatv(R"(
.tk{index}_valid(tk{index}_valid),
.tk{index}_ready(tk{index}_ready),
.tk{index}_enable(tk{index}_enable),
.tk{index}_data(tk{index}_data),
    )");
  }

  TraceBackendImpl(const TraceConfig *config) : BaseImpl(config) {}

  string instanceFIFOTrans() {
    return
#include "vtemplate/FIFOTrans.inc"
        ;
  }

  string emitVerilog() override {
    auto fifoTrans =
#include "vtemplate/FIFOTrans.inc"
        ;

    auto fifoAXI4Ctrl =
#include "vtemplate/FIFOAXI4Ctrl.inc"
        ;

    auto batch = TraceBatch(config).emitVerilog();

    /* clang-format off */ 
  auto top = fmt::format(
#include "vtemplate/TraceBackend.inc"
    ,fmt::arg("moduleName", moduleName)
    ,fmt::arg("traceNR", traceNR)
    ,fmt::arg("packSumWidth", packSumWidth)
    ,fmt::arg("outDataWidth", outDataWidth)
    ,fmt::arg("outLenWidth", outLenWidth)
    ,fmt::arg("markInfoValue", markInfoValue())
    ,fmt::arg("markDataWidth", markDataWidth())
    ,fmt::arg("infoWidth", infoWidth())
    ,fmt::arg("tracePortDefine", tracePortDefine())
    ,fmt::arg("tracePortInstance", tracePortInstance())
  );
    /* clang-format on */
  return top + batch + fifoAXI4Ctrl + fifoTrans;
  }
};

string TraceBackend::emitVerilog() {
  return TraceBackendImpl(this).emitVerilog();
}
string TraceBackend::emitCHeader() {
  return TraceBackendImpl(this).emitCHeader();
}