
#include "TraceBackend/Top.hpp"
#include "TraceBackend/utils.hpp"
#include <cassert>
#include <numeric>

class BaseImpl {

public:
  std::string moduleName = "TraceBatch";
  const TraceConfig *config;

  std::vector<size_t> portWidth;
  std::vector<size_t> packWidth;
  std::vector<size_t> pipeWidth;
  size_t traceNR;
  size_t markInfoValue() { return config->markInfoValue; }
  size_t markDataWidth() { return config->markDataWidth; }
  size_t infoBytes() { return config->infoBytes; }
  size_t AXI4DataWidth() { return config->AXI4DataWidth; }
  size_t infoWidth() { return infoBytes() * 8; }
  size_t packSumWidth;
  size_t outDataWidth;
  size_t outLenWidth;

  std::string formatv(std::string fmtStr, std::string delim = "\n",
                      std::string begin = "", std::string end = "",
                      bool reverse = false) {
    auto func = [fmtStr](size_t w, size_t i) {
      return fmt::format(fmtStr, fmt::arg("index", i), fmt::arg("width", w));
    };
    auto strVec = std::vector<std::string>(traceNR);
    for (size_t i = 0; i < traceNR; i++) {
      strVec[i] = fmt::format(fmtStr, fmt::arg("index", i),
                              fmt::arg("traceNR", traceNR),
                              fmt::arg("portWidth", portWidth[i]),
                              fmt::arg("packWidth", packWidth[i]),
                              fmt::arg("pipeWidth", pipeWidth[i]));
    }
    return utils::mkString(strVec, delim, begin, end, reverse);
  }

  std::string tracePortDefine() {
    return formatv(R"(
input   wire tk{index}_valid,
output  wire tk{index}_ready,
input   wire tk{index}_enable,
input   wire [{portWidth}-1:0] tk{index}_data,
    )");
  }

  BaseImpl(const TraceConfig *traceConfig)
      : config(traceConfig), portWidth(config->tracePortsWidth),
        traceNR(portWidth.size()) {
    pipeWidth = std::vector<size_t>(traceNR);
    packWidth = std::vector<size_t>(traceNR);
    for (size_t i = 0; i < traceNR; i++) {
      pipeWidth[i] = 0;
    }
    for (size_t i = 0; i < traceNR; i++) {
      packWidth[i] = utils::intCeil(portWidth[i], 8) + infoWidth();
      for (size_t j = i; j < traceNR; j++) {
        pipeWidth[j] += packWidth[i];
      }
    }
    // Assert pipeWidth and packWidth are bytes
    for (size_t i = 0; i < traceNR; i++) {
      assert(pipeWidth[i] % 8 == 0);
      assert(packWidth[i] % 8 == 0);
    }
    packSumWidth = std::accumulate(packWidth.begin(), packWidth.end(), 0);
    outDataWidth = utils::intCeil(packSumWidth + infoWidth() + markDataWidth(),
                                  AXI4DataWidth());
    outLenWidth = std::ceil(std::log2(outDataWidth / 8));
  }

  virtual std::string emitVerilog() = 0;
  std::string emitCHeader();
};
