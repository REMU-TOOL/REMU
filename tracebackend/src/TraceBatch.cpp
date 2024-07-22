#include "TraceBackend/Top.hpp"
#include "include/TraceBase.hpp"
#include "include/utils.hpp"
#include <cassert>
#include <cstddef>
#include <fmt/core.h>
#include <vector>

using namespace utils;
using std::string;
using std::vector;
class TraceBatchImpl : public BaseImpl {
public:
  string moduleName = "TraceBatch";

  string tracePortDefine() {
    return formatv(R"(
input   wire tk{index}_valid,
output  wire tk{index}_ready,
input   wire tk{index}_enable,
input   wire [{portWidth}-1:0] tk{index}_data,
    )");
  }

  string traceWidthParams() {
    return formatv("localparam TRACE{index}_DATA_WIDTH = {portWidth};");
  }

  string inputValids() {
    return formatv("tk{index}_valid", ", ", "{", "}", true);
  }
  string inputReadys() {
    return formatv("tk{index}_ready", ", ", "{", "}", true);
  }

  string totalPackWidth() {
    return formatv("packWidth(TRACE{index}_DATA_WDITH)", "+ ");
  }

  string packVecDefine() {
    auto packVecDefines = vector<string>(traceNR);
    for (size_t i = 0; i < traceNR; i++)
      packVecDefines[i] = fmt::format("reg [{}:0] pack{}Vec [{}:0];",
                                      pipeWidth[i] - 1, i, traceNR);
    return mkString(packVecDefines);
  }

  string enableVecInit() {
    return formatv("tk{index}_enable", ", ", "{", "}", true);
  }

  string bufferValidInit() { return formatv("tk{index}_enable", "|| "); }

  string packVecInit() {
    auto packVecAssign = vector<string>(traceNR);
    for (size_t i = 0; i < traceNR; i++) {
      auto elems = vector<size_t>(packWidth.begin(), packWidth.begin() + i + 1);
      auto strVec = vector<string>(elems.size());
      for (size_t j = 0; j < i + 1; j++) {
        strVec[j] = fmt::format("{}'d0", elems[j]);
      }
      auto emptyWidth = packWidth[i] - portWidth[i] - 8;
      auto headZero = emptyWidth == 0 ? "" : fmt::format("{}'d0,", emptyWidth);
      strVec[i] =
          fmt::format("{} tk{}_data, {}'d{}", headZero, i, infoWidth(), i);
      packVecAssign[i] = mkString(
          strVec, ", ", fmt::format("pack{}Vec[0] <= {{", i), "};\n", true);
    }
    return mkString(packVecAssign);
  }

  string asisgnTraceReady() {
    return formatv(
        "assign tk{index}_ready = !bufferValid || pipeReady[{index}];");
  }

  string pipeline() {
    auto alwaysBlocks = vector<string>(traceNR);
    for (size_t pipeLv = 0; pipeLv < traceNR; pipeLv++) {
      auto enableAssign = vector<string>(traceNR);
      auto disableAssign = vector<string>(traceNR);
      for (size_t i = 0; i < traceNR; i++) {
        enableAssign[i] = fmt::format("pack{}Vec[{}] <= pack{}Vec[{}];", i,
                                      pipeLv, i, pipeLv + 1);
        if (i < pipeLv) {
          disableAssign[i] = fmt::format("pack{}Vec[{}] <= pack{}Vec[{}];", i,
                                         pipeLv, i, pipeLv + 1);
        } else if (i == pipeLv) {
          disableAssign[i] = fmt::format("pack{}Vec[{}] <= 0;", i, pipeLv);
        } else {
          disableAssign[i] =
              fmt::format("pack{}Vec[{}] <= pack{}Vec[{}] >> {};", i, pipeLv, i,
                          pipeLv + 1, packWidth[pipeLv]);
        }
      }

      alwaysBlocks[pipeLv] = fmt::format(
          R"(
    always @(posedge clk) begin
        if (pipeValid[{pipeLv}] && pipeReady[{pipeLv}]) begin
            enableVec[{nextPipeLv}] <= enableVec[{pipeLv}];
            if (enableVec[{pipeLv}][{pipeLv}]) begin
                {enableAssign}
                widthVec[{nextPipeLv}] <= widthVec[{pipeLv}] + {outLenWidth}'d{packBytes};
            end
            else begin
                {disableAssign}
                widthVec[{nextPipeLv}] <= widthVec[{pipeLv}];
            end
        end
    end
      )",
          fmt::arg("pipeLv", pipeLv), fmt::arg("nextPipeLv", pipeLv + 1),
          fmt::arg("outLenWidth", outLenWidth),
          fmt::arg("packBytes", packWidth[pipeLv] / 8),
          fmt::arg("enableAssign", mkString(enableAssign)),
          fmt::arg("disableAssign", mkString(disableAssign)));
    }
    return mkString(alwaysBlocks);
  }

  string pipeDataOut() {
    auto lastLvData = vector<string>(traceNR);
    // {{'d0 endData, 8'd128}, ({'d0, pack0Vec[3]} | {'d0, packnVec[3]})};
    for (size_t i = 0; i < traceNR - 1; i++) {
      lastLvData[i] =
          fmt::format("{{{}'d0, pack{}Vec[{}]}}",
                      pipeWidth[traceNR - 1] - pipeWidth[i], i, traceNR);
    }
    lastLvData[traceNR - 1] =
        fmt::format("pack{}Vec[{}]", traceNR - 1, traceNR);
    auto emptyWidth =
        outDataWidth - infoWidth() - endDataWidth() - pipeWidth[traceNR - 1];
    assert(emptyWidth % 8 == 0);
    auto headZero = emptyWidth == 0 ? "" : fmt::format("{}'d0,", emptyWidth);
    auto endPack = fmt::format("{{ {} endData, {}'d{} }}", headZero,
                               infoWidth(), endInfoValue());
    auto tracePacks = mkString(lastLvData, " | ", "(", ")");
    return fmt::format("{{ {}, {} }}", endPack, tracePacks);
  }
  string pipeLenOut() {
    return fmt::format("widthVec[{}] + {}'d{}", traceNR, outLenWidth,
                       (endDataWidth() + infoWidth()) / 8);
  }

public:
  TraceBatchImpl(const TraceConfig *config) : BaseImpl(config) {}
  string emitVerilog() {
    /* clang-format off */ 
  return fmt::format(
#include "vtemplate/TraceBatch.inc"
    ,fmt::arg("moduleName", moduleName)
    ,fmt::arg("traceNR", traceNR)
    ,fmt::arg("packSumWidth", packSumWidth)
    ,fmt::arg("outDataWidth", outDataWidth)
    ,fmt::arg("outLenWidth", outLenWidth)
    ,fmt::arg("endInfoValue", endInfoValue())
    ,fmt::arg("endDataWidth", endDataWidth())
    ,fmt::arg("infoWidth", infoWidth())
    ,fmt::arg("tracePortDefine", tracePortDefine())
    ,fmt::arg("traceWidthParams", traceWidthParams())
    ,fmt::arg("inputValids", inputValids())
    ,fmt::arg("inputReadys", inputReadys())
    ,fmt::arg("totalPackWidth", totalPackWidth())
    ,fmt::arg("packVecDefine", packVecDefine())
    ,fmt::arg("enableVecInit", enableVecInit())
    ,fmt::arg("bufferValidInit", bufferValidInit())
    ,fmt::arg("packVecInit", packVecInit())
    ,fmt::arg("asisgnTraceReady", asisgnTraceReady())
    ,fmt::arg("pipeline", pipeline())
    ,fmt::arg("pipeDataOut", pipeDataOut())
    ,fmt::arg("pipeLenOut", pipeLenOut())
  );
    /* clang-format on */
  }
};

string TraceBatch::emitVerilog() { return TraceBatchImpl(this).emitVerilog(); }