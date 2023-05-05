module emulib_fased_DownCounter(
  input        clock,
  input        reset,
  input        io_set_valid,
  input  [6:0] io_set_bits,
  output       io_idle,
  input        targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg [6:0] delay; // @[Util.scala 175:22]
  wire [6:0] _delay_T_1 = delay - 7'h1; // @[Util.scala 179:20]
  assign io_idle = delay == 7'h0; // @[Util.scala 181:20]
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[Util.scala 175:22]
      delay <= 7'h0; // @[Util.scala 175:22]
    end else if (targetFire) begin
      if (io_set_valid & io_set_bits >= delay) begin // @[Util.scala 176:46]
        delay <= io_set_bits; // @[Util.scala 177:11]
      end else if (delay != 7'h0) begin // @[Util.scala 178:39]
        delay <= _delay_T_1; // @[Util.scala 179:11]
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
  delay = _RAND_0[6:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module emulib_fased_DownCounter_2(
  input        clock,
  input        reset,
  input        io_set_valid,
  input  [9:0] io_set_bits,
  output [9:0] io_current,
  output       io_idle,
  input        targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg [9:0] delay; // @[Util.scala 175:22]
  wire [9:0] _delay_T_1 = delay - 10'h1; // @[Util.scala 179:20]
  assign io_current = delay; // @[Util.scala 182:14]
  assign io_idle = delay == 10'h0; // @[Util.scala 181:20]
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[Util.scala 175:22]
      delay <= 10'h0; // @[Util.scala 175:22]
    end else if (targetFire) begin
      if (io_set_valid & io_set_bits >= delay) begin // @[Util.scala 176:46]
        delay <= io_set_bits; // @[Util.scala 177:11]
      end else if (delay != 10'h0) begin // @[Util.scala 178:39]
        delay <= _delay_T_1; // @[Util.scala 179:11]
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
  delay = _RAND_0[9:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule

module emulib_fased_SatUpDownCounter_8(
  input        clock,
  input        reset,
  input        io_inc,
  input        io_dec,
  output [3:0] io_value,
  output       io_full,
  output       io_empty,
  input        targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg [3:0] value; // @[Lib.scala 74:23]
  wire [3:0] _value_T_1 = value + 4'h1; // @[Lib.scala 82:20]
  wire [3:0] _value_T_3 = value - 4'h1; // @[Lib.scala 84:20]
  assign io_value = value; // @[Lib.scala 79:23 Lib.scala 80:14 Lib.scala 75:12]
  assign io_full = value >= 4'ha; // @[Lib.scala 76:20]
  assign io_empty = value == 4'h0; // @[Lib.scala 77:21]
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[Lib.scala 74:23]
      value <= 4'h0; // @[Lib.scala 74:23]
    end else if (targetFire) begin
      if (io_inc & ~io_dec & ~io_full) begin // @[Lib.scala 81:46]
        value <= _value_T_1; // @[Lib.scala 82:11]
      end else if (~io_inc & io_dec & ~io_empty) begin // @[Lib.scala 83:45]
        value <= _value_T_3; // @[Lib.scala 84:11]
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
  value = _RAND_0[3:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule