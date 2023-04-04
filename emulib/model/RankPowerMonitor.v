module RankPowerMonitor(
  input         clock,
  input         reset,
  output [31:0] io_stats_allPreCycles,
  output [31:0] io_stats_numCASR,
  output [31:0] io_stats_numCASW,
  output [31:0] io_stats_numACT,
  input         io_rankState_state,
  input         io_rankState_banks_0_canACT,
  input         io_rankState_banks_1_canACT,
  input         io_rankState_banks_2_canACT,
  input         io_rankState_banks_3_canACT,
  input         io_rankState_banks_4_canACT,
  input         io_rankState_banks_5_canACT,
  input         io_rankState_banks_6_canACT,
  input         io_rankState_banks_7_canACT,
  input  [2:0]  io_selectedCmd,
  input         io_cmdUsesThisRank,
  input         targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg [31:0] stats_allPreCycles; // @[DramCommon.scala 681:22]
  reg [31:0] stats_numCASR; // @[DramCommon.scala 681:22]
  reg [31:0] stats_numCASW; // @[DramCommon.scala 681:22]
  reg [31:0] stats_numACT; // @[DramCommon.scala 681:22]
  wire  _T = 3'h1 == io_selectedCmd; // @[Conditional.scala 37:30]
  wire [31:0] _stats_numACT_T_1 = stats_numACT + 32'h1; // @[DramCommon.scala 686:38]
  wire  _T_1 = 3'h3 == io_selectedCmd; // @[Conditional.scala 37:30]
  wire [31:0] _stats_numCASW_T_1 = stats_numCASW + 32'h1; // @[DramCommon.scala 689:40]
  wire  _T_2 = 3'h4 == io_selectedCmd; // @[Conditional.scala 37:30]
  wire [31:0] _stats_numCASR_T_1 = stats_numCASR + 32'h1; // @[DramCommon.scala 692:40]
  wire [31:0] _GEN_0 = _T_2 ? _stats_numCASR_T_1 : stats_numCASR; // @[Conditional.scala 39:67 DramCommon.scala 692:23 DramCommon.scala 681:22]
  wire [31:0] _GEN_1 = _T_1 ? _stats_numCASW_T_1 : stats_numCASW; // @[Conditional.scala 39:67 DramCommon.scala 689:23 DramCommon.scala 681:22]
  wire [31:0] _GEN_2 = _T_1 ? stats_numCASR : _GEN_0; // @[Conditional.scala 39:67 DramCommon.scala 681:22]
  wire [31:0] _stats_allPreCycles_T_1 = stats_allPreCycles + 32'h1; // @[DramCommon.scala 699:46]
  assign io_stats_allPreCycles = stats_allPreCycles; // @[DramCommon.scala 702:12]
  assign io_stats_numCASR = stats_numCASR; // @[DramCommon.scala 702:12]
  assign io_stats_numCASW = stats_numCASW; // @[DramCommon.scala 702:12]
  assign io_stats_numACT = stats_numACT; // @[DramCommon.scala 702:12]
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[DramCommon.scala 681:22]
      stats_allPreCycles <= 32'h0; // @[DramCommon.scala 681:22]
    end else if (targetFire) begin
      if (~io_rankState_state & (io_rankState_banks_0_canACT & io_rankState_banks_1_canACT & io_rankState_banks_2_canACT
         & io_rankState_banks_3_canACT & io_rankState_banks_4_canACT & io_rankState_banks_5_canACT &
        io_rankState_banks_6_canACT & io_rankState_banks_7_canACT)) begin // @[DramCommon.scala 698:92]
        stats_allPreCycles <= _stats_allPreCycles_T_1; // @[DramCommon.scala 699:24]
      end
    end
    if (reset & targetFire) begin // @[DramCommon.scala 681:22]
      stats_numCASR <= 32'h0; // @[DramCommon.scala 681:22]
    end else if (targetFire) begin
      if (io_cmdUsesThisRank) begin // @[DramCommon.scala 683:29]
        if (!(_T)) begin // @[Conditional.scala 40:58]
          stats_numCASR <= _GEN_2;
        end
      end
    end
    if (reset & targetFire) begin // @[DramCommon.scala 681:22]
      stats_numCASW <= 32'h0; // @[DramCommon.scala 681:22]
    end else if (targetFire) begin
      if (io_cmdUsesThisRank) begin // @[DramCommon.scala 683:29]
        if (!(_T)) begin // @[Conditional.scala 40:58]
          stats_numCASW <= _GEN_1;
        end
      end
    end
    if (reset & targetFire) begin // @[DramCommon.scala 681:22]
      stats_numACT <= 32'h0; // @[DramCommon.scala 681:22]
    end else if (targetFire) begin
      if (io_cmdUsesThisRank) begin // @[DramCommon.scala 683:29]
        if (_T) begin // @[Conditional.scala 40:58]
          stats_numACT <= _stats_numACT_T_1; // @[DramCommon.scala 686:22]
        end
      end
    end
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {1{`RANDOM}};
  stats_allPreCycles = _RAND_0[31:0];
  _RAND_1 = {1{`RANDOM}};
  stats_numCASR = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  stats_numCASW = _RAND_2[31:0];
  _RAND_3 = {1{`RANDOM}};
  stats_numACT = _RAND_3[31:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule