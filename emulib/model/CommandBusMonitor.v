module CommandBusMonitor(
  input         clock,
  input         reset,
  input  [2:0]  io_cmd,
  input  [1:0]  io_rank,
  input  [2:0]  io_bank,
  input  [25:0] io_row,
  input         io_autoPRE,
  input         targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
`endif // RANDOMIZE_REG_INIT
  reg [31:0] cycleCounter; // @[DramCommon.scala 577:29]
  reg [31:0] lastCommand; // @[DramCommon.scala 578:28]
  wire [31:0] _cycleCounter_T_1 = cycleCounter + 32'h1; // @[DramCommon.scala 579:32]
  wire  _T = io_cmd != 3'h0; // @[DramCommon.scala 580:16]
  wire [31:0] _T_2 = lastCommand + 32'h1; // @[DramCommon.scala 582:23]
  wire [31:0] _T_5 = cycleCounter - lastCommand; // @[DramCommon.scala 582:83]
  wire  _T_9 = ~reset; // @[DramCommon.scala 582:55]
  wire  _T_10 = 3'h1 == io_cmd; // @[Conditional.scala 37:30]
  wire  _T_13 = 3'h4 == io_cmd; // @[Conditional.scala 37:30]
  wire  _T_16 = 3'h3 == io_cmd; // @[Conditional.scala 37:30]
  wire  _T_19 = 3'h5 == io_cmd; // @[Conditional.scala 37:30]
  wire  _T_22 = 3'h2 == io_cmd; // @[Conditional.scala 37:30]
  wire  _GEN_6 = ~_T_10; // @[DramCommon.scala 593:13]
  wire  _GEN_11 = _GEN_6 & ~_T_13; // @[DramCommon.scala 602:13]
  wire  _GEN_18 = _GEN_11 & ~_T_16; // @[DramCommon.scala 606:13]
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[DramCommon.scala 577:29]
      cycleCounter <= 32'h1; // @[DramCommon.scala 577:29]
    end else if (targetFire) begin
      cycleCounter <= _cycleCounter_T_1; // @[DramCommon.scala 579:16]
    end
    if (reset & targetFire) begin // @[DramCommon.scala 578:28]
      lastCommand <= 32'h0; // @[DramCommon.scala 578:28]
    end else if (targetFire) begin
      if (io_cmd != 3'h0) begin // @[DramCommon.scala 580:29]
        lastCommand <= cycleCounter; // @[DramCommon.scala 581:17]
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T & _T_2 != cycleCounter & ~reset & targetFire) begin
          $fwrite(32'h80000002,"nop(%d);\n",_T_5 - 32'h1); // @[DramCommon.scala 582:55]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_T_10 & _T_9 & targetFire) begin
          $fwrite(32'h80000002,"activate(%d, %d, %d); // %d\n",io_rank,io_bank,io_row,cycleCounter); // @[DramCommon.scala 587:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~_T_10 & _T_13 & _T_9 & targetFire) begin
          $fwrite(32'h80000002,"read(%d, %d, %d, %x, %x); // %d\n",io_rank,io_bank,1'h0,io_autoPRE,1'h0,cycleCounter); // @[DramCommon.scala 593:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_6 & ~_T_13 & _T_16 & _T_9 & targetFire) begin
          $fwrite(32'h80000002,"write(%d, %d, %d, %x, %x, %d, %d); // %d\n",io_rank,io_bank,1'h0,io_autoPRE,1'h0,1'h0,1'h0
            ,cycleCounter); // @[DramCommon.scala 602:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_11 & ~_T_16 & _T_19 & _T_9 & targetFire) begin
          $fwrite(32'h80000002,"refresh(%d); // %d\n",io_rank,cycleCounter); // @[DramCommon.scala 606:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_18 & ~_T_19 & _T_22 & _T_9 & targetFire) begin
          $fwrite(32'h80000002,"precharge(%d,%d,%d); // %d\n",io_rank,io_bank,1'h0,cycleCounter); // @[DramCommon.scala 610:13]
        end
    `ifdef PRINTF_COND
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
  cycleCounter = _RAND_0[31:0];
  _RAND_1 = {1{`RANDOM}};
  lastCommand = _RAND_1[31:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule