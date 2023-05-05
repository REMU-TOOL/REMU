module emulib_fased_BankStateTracker(
  input         clock,
  input         reset,
  input  [6:0]  io_timings_tAL,
  input  [6:0]  io_timings_tCWD,
  input  [6:0]  io_timings_tCCD,
  input  [6:0]  io_timings_tRAS,
  input  [6:0]  io_timings_tRC,
  input  [6:0]  io_timings_tRCD,
  input  [6:0]  io_timings_tRP,
  input  [6:0]  io_timings_tRTP,
  input  [6:0]  io_timings_tWR,
  input  [2:0]  io_selectedCmd,
  input         io_autoPRE,
  input  [25:0] io_cmdRow,
  output        io_out_canCASW,
  output        io_out_canCASR,
  output        io_out_canPRE,
  output        io_out_canACT,
  output [25:0] io_out_openRow,
  output        io_out_state,
  input         io_cmdUsesThisBank,
  input         targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  wire  nextLegalPRE_clock;
  wire  nextLegalPRE_reset;
  wire  nextLegalPRE_io_set_valid;
  wire [6:0] nextLegalPRE_io_set_bits;
  wire  nextLegalPRE_io_idle;
  wire  nextLegalPRE_targetFire;
  wire  nextLegalACT_clock;
  wire  nextLegalACT_reset;
  wire  nextLegalACT_io_set_valid;
  wire [6:0] nextLegalACT_io_set_bits;
  wire  nextLegalACT_io_idle;
  wire  nextLegalACT_targetFire;
  wire  nextLegalCAS_clock;
  wire  nextLegalCAS_reset;
  wire  nextLegalCAS_io_set_valid;
  wire [6:0] nextLegalCAS_io_set_bits;
  wire  nextLegalCAS_io_idle;
  wire  nextLegalCAS_targetFire;
  reg  state; // @[DramCommon.scala 375:22]
  reg [25:0] openRowAddr; // @[DramCommon.scala 376:24]
  wire  _T = 3'h1 == io_selectedCmd; // @[Conditional.scala 37:30]
  wire [6:0] _nextLegalCAS_io_set_bits_T_1 = io_timings_tRCD - io_timings_tAL; // @[DramCommon.scala 395:53]
  wire [6:0] _nextLegalPRE_io_set_bits_T_1 = io_timings_tRAS - 7'h1; // @[DramCommon.scala 397:53]
  wire [6:0] _nextLegalACT_io_set_bits_T_1 = io_timings_tRC - 7'h1; // @[DramCommon.scala 399:52]
  wire  _T_4 = 3'h4 == io_selectedCmd; // @[Conditional.scala 37:30]
  wire [6:0] _nextLegalACT_io_set_bits_T_3 = io_timings_tRTP + io_timings_tAL; // @[DramCommon.scala 406:55]
  wire [6:0] _nextLegalACT_io_set_bits_T_5 = _nextLegalACT_io_set_bits_T_3 + io_timings_tRP; // @[DramCommon.scala 406:72]
  wire [6:0] _nextLegalACT_io_set_bits_T_7 = _nextLegalACT_io_set_bits_T_5 - 7'h1; // @[DramCommon.scala 406:89]
  wire [6:0] _nextLegalPRE_io_set_bits_T_5 = _nextLegalACT_io_set_bits_T_3 - 7'h1; // @[DramCommon.scala 409:72]
  wire  _GEN_0 = io_autoPRE ? 1'h0 : state; // @[DramCommon.scala 403:27 DramCommon.scala 404:17 DramCommon.scala 375:22]
  wire  _GEN_3 = io_autoPRE ? 1'h0 : 1'h1; // @[DramCommon.scala 403:27 DramCommon.scala 384:22 DramCommon.scala 408:37]
  wire  _T_8 = 3'h3 == io_selectedCmd; // @[Conditional.scala 37:30]
  wire [6:0] _nextLegalACT_io_set_bits_T_9 = io_timings_tCWD + io_timings_tAL; // @[DramCommon.scala 417:55]
  wire [6:0] _nextLegalACT_io_set_bits_T_11 = _nextLegalACT_io_set_bits_T_9 + io_timings_tWR; // @[DramCommon.scala 417:72]
  wire [6:0] _nextLegalACT_io_set_bits_T_13 = _nextLegalACT_io_set_bits_T_11 + io_timings_tCCD; // @[DramCommon.scala 417:89]
  wire [6:0] _nextLegalACT_io_set_bits_T_15 = _nextLegalACT_io_set_bits_T_13 + io_timings_tRP; // @[DramCommon.scala 418:29]
  wire [6:0] _nextLegalACT_io_set_bits_T_17 = _nextLegalACT_io_set_bits_T_15 + 7'h1; // @[DramCommon.scala 418:46]
  wire [6:0] _nextLegalPRE_io_set_bits_T_13 = _nextLegalACT_io_set_bits_T_13 - 7'h1; // @[DramCommon.scala 422:29]
  wire  _T_12 = 3'h2 == io_selectedCmd; // @[Conditional.scala 37:30]
  wire [6:0] _nextLegalACT_io_set_bits_T_19 = io_timings_tRP - 7'h1; // @[DramCommon.scala 429:52]
  wire  _GEN_7 = _T_12 ? 1'h0 : state; // @[Conditional.scala 39:67 DramCommon.scala 427:15 DramCommon.scala 375:22]
  wire  _GEN_10 = _T_8 ? _GEN_0 : _GEN_7; // @[Conditional.scala 39:67]
  wire  _GEN_11 = _T_8 ? io_autoPRE : _T_12; // @[Conditional.scala 39:67]
  wire [6:0] _GEN_12 = _T_8 ? _nextLegalACT_io_set_bits_T_17 : _nextLegalACT_io_set_bits_T_19; // @[Conditional.scala 39:67]
  wire  _GEN_13 = _T_8 & _GEN_3; // @[Conditional.scala 39:67 DramCommon.scala 384:22]
  wire  _GEN_15 = _T_4 ? _GEN_0 : _GEN_10; // @[Conditional.scala 39:67]
  wire  _GEN_16 = _T_4 ? io_autoPRE : _GEN_11; // @[Conditional.scala 39:67]
  wire [6:0] _GEN_17 = _T_4 ? _nextLegalACT_io_set_bits_T_7 : _GEN_12; // @[Conditional.scala 39:67]
  wire  _GEN_18 = _T_4 ? _GEN_3 : _GEN_13; // @[Conditional.scala 39:67]
  wire [6:0] _GEN_19 = _T_4 ? _nextLegalPRE_io_set_bits_T_5 : _nextLegalPRE_io_set_bits_T_13; // @[Conditional.scala 39:67]
  wire  _GEN_20 = _T | _GEN_15; // @[Conditional.scala 40:58 DramCommon.scala 392:15]
  wire  _GEN_24 = _T | _GEN_18; // @[Conditional.scala 40:58 DramCommon.scala 396:35]
  wire  _GEN_26 = _T | _GEN_16; // @[Conditional.scala 40:58 DramCommon.scala 398:35]
  wire  _GEN_30 = io_cmdUsesThisBank & _T; // @[DramCommon.scala 388:29 DramCommon.scala 384:22]
  wire  _GEN_43 = io_cmdUsesThisBank & ~_T; // @[DramCommon.scala 402:15]
  wire  _GEN_53 = _GEN_43 & ~_T_4; // @[DramCommon.scala 413:15]
  emulib_fased_DownCounter nextLegalPRE (
    .clock(nextLegalPRE_clock),
    .reset(nextLegalPRE_reset),
    .io_set_valid(nextLegalPRE_io_set_valid),
    .io_set_bits(nextLegalPRE_io_set_bits),
    .io_idle(nextLegalPRE_io_idle),
    .targetFire(nextLegalPRE_targetFire)
  );
  emulib_fased_DownCounter nextLegalACT (
    .clock(nextLegalACT_clock),
    .reset(nextLegalACT_reset),
    .io_set_valid(nextLegalACT_io_set_valid),
    .io_set_bits(nextLegalACT_io_set_bits),
    .io_idle(nextLegalACT_io_idle),
    .targetFire(nextLegalACT_targetFire)
  );
  emulib_fased_DownCounter nextLegalCAS (
    .clock(nextLegalCAS_clock),
    .reset(nextLegalCAS_reset),
    .io_set_valid(nextLegalCAS_io_set_valid),
    .io_set_bits(nextLegalCAS_io_set_bits),
    .io_idle(nextLegalCAS_io_idle),
    .targetFire(nextLegalCAS_targetFire)
  );
  assign io_out_canCASW = state & nextLegalCAS_io_idle; // @[DramCommon.scala 434:45]
  assign io_out_canCASR = state & nextLegalCAS_io_idle; // @[DramCommon.scala 435:45]
  assign io_out_canPRE = state & nextLegalPRE_io_idle; // @[DramCommon.scala 436:44]
  assign io_out_canACT = ~state & nextLegalACT_io_idle; // @[DramCommon.scala 437:42]
  assign io_out_openRow = openRowAddr; // @[DramCommon.scala 439:18]
  assign io_out_state = state; // @[DramCommon.scala 438:16]
  assign nextLegalPRE_clock = clock;
  assign nextLegalPRE_reset = reset;
  assign nextLegalPRE_io_set_valid = io_cmdUsesThisBank & _GEN_24; // @[DramCommon.scala 388:29 DramCommon.scala 384:22]
  assign nextLegalPRE_io_set_bits = _T ? _nextLegalPRE_io_set_bits_T_1 : _GEN_19; // @[Conditional.scala 40:58 DramCommon.scala 397:34]
  assign nextLegalPRE_targetFire = targetFire;
  assign nextLegalACT_clock = clock;
  assign nextLegalACT_reset = reset;
  assign nextLegalACT_io_set_valid = io_cmdUsesThisBank & _GEN_26; // @[DramCommon.scala 388:29 DramCommon.scala 384:22]
  assign nextLegalACT_io_set_bits = _T ? _nextLegalACT_io_set_bits_T_1 : _GEN_17; // @[Conditional.scala 40:58 DramCommon.scala 399:34]
  assign nextLegalACT_targetFire = targetFire;
  assign nextLegalCAS_clock = clock;
  assign nextLegalCAS_reset = reset;
  assign nextLegalCAS_io_set_valid = io_cmdUsesThisBank & _T; // @[DramCommon.scala 388:29 DramCommon.scala 384:22]
  assign nextLegalCAS_io_set_bits = _nextLegalCAS_io_set_bits_T_1 - 7'h1; // @[DramCommon.scala 395:70]
  assign nextLegalCAS_targetFire = targetFire;
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[DramCommon.scala 375:22]
      state <= 1'h0; // @[DramCommon.scala 375:22]
    end else if (targetFire) begin
      if (io_cmdUsesThisBank) begin // @[DramCommon.scala 388:29]
        state <= _GEN_20;
      end
    end
    if (targetFire) begin
      if (io_cmdUsesThisBank) begin // @[DramCommon.scala 388:29]
        if (_T) begin // @[Conditional.scala 40:58]
          openRowAddr <= io_cmdRow; // @[DramCommon.scala 393:21]
        end
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_30 & ~(io_out_canACT | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Bank Timing Violation: Controller issued activate command illegally\n    at DramCommon.scala:391 assert(io.out.canACT, \"Bank Timing Violation: Controller issued activate command illegally\")\n"
            ); // @[DramCommon.scala 391:15]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_GEN_30 & ~(io_out_canACT | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 391:15]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (io_cmdUsesThisBank & ~_T & _T_4 & ~(io_out_canCASR | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Bank Timing Violation: Controller issued CASR command illegally\n    at DramCommon.scala:402 assert(io.out.canCASR, \"Bank Timing Violation: Controller issued CASR command illegally\")\n"
            ); // @[DramCommon.scala 402:15]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (io_cmdUsesThisBank & ~_T & _T_4 & ~(io_out_canCASR | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 402:15]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_43 & ~_T_4 & _T_8 & ~(io_out_canCASW | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Bank Timing Violation: Controller issued CASW command illegally\n    at DramCommon.scala:413 assert(io.out.canCASW, \"Bank Timing Violation: Controller issued CASW command illegally\")\n"
            ); // @[DramCommon.scala 413:15]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_GEN_43 & ~_T_4 & _T_8 & ~(io_out_canCASW | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 413:15]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_53 & ~_T_8 & _T_12 & ~(io_out_canPRE | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Bank Timing Violation: Controller issued PRE command illegally\n    at DramCommon.scala:426 assert(io.out.canPRE, \"Bank Timing Violation: Controller issued PRE command illegally\")\n"
            ); // @[DramCommon.scala 426:15]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_GEN_53 & ~_T_8 & _T_12 & ~(io_out_canPRE | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 426:15]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
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
  state = _RAND_0[0:0];
  _RAND_1 = {1{`RANDOM}};
  openRowAddr = _RAND_1[25:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule