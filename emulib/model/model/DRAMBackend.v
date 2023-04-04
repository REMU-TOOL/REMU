module DynamicLatencyPipe(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [3:0]  io_enq_bits_id,
  input         io_deq_ready,
  output        io_deq_valid,
  output [3:0]  io_deq_bits_id,
  input  [11:0] io_latency,
  input  [11:0] io_tCycle,
  input         targetFire
);
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
`endif // RANDOMIZE_REG_INIT
  reg [3:0] ram_id [0:3]; // @[Util.scala 125:16]
  wire [3:0] ram_id_io_deq_bits_MPORT_data; // @[Util.scala 125:16]
  wire [1:0] ram_id_io_deq_bits_MPORT_addr; // @[Util.scala 125:16]
  wire [3:0] ram_id_MPORT_data; // @[Util.scala 125:16]
  wire [1:0] ram_id_MPORT_addr; // @[Util.scala 125:16]
  wire  ram_id_MPORT_mask; // @[Util.scala 125:16]
  wire  ram_id_MPORT_en; // @[Util.scala 125:16]
  reg [1:0] value; // @[Counter.scala 60:40]
  reg [1:0] value_1; // @[Counter.scala 60:40]
  reg  maybe_full; // @[Util.scala 90:27]
  wire  ptr_match = value == value_1; // @[Util.scala 92:33]
  wire  empty = ptr_match & ~maybe_full; // @[Util.scala 93:25]
  wire  full = ptr_match & maybe_full; // @[Util.scala 94:24]
  wire [1:0] _value_T_1 = value + 2'h1; // @[Counter.scala 76:24]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 40:37]
  wire [1:0] _value_T_3 = value_1 + 2'h1; // @[Counter.scala 76:24]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 40:37]
  reg [11:0] latencies_0; // @[Util.scala 147:22]
  reg [11:0] latencies_1; // @[Util.scala 147:22]
  reg [11:0] latencies_2; // @[Util.scala 147:22]
  reg [11:0] latencies_3; // @[Util.scala 147:22]
  reg  pendingRegisters_0; // @[Util.scala 148:33]
  reg  pendingRegisters_1; // @[Util.scala 148:33]
  reg  pendingRegisters_2; // @[Util.scala 148:33]
  reg  pendingRegisters_3; // @[Util.scala 148:33]
  wire  done_cycleMatch = latencies_0 == io_tCycle; // @[Util.scala 150:26]
  wire  _GEN_9 = done_cycleMatch ? 1'h0 : pendingRegisters_0; // @[Util.scala 151:23 Util.scala 151:36 Util.scala 148:33]
  wire  done_0 = done_cycleMatch | ~pendingRegisters_0; // @[Util.scala 152:16]
  wire  done_cycleMatch_1 = latencies_1 == io_tCycle; // @[Util.scala 150:26]
  wire  _GEN_10 = done_cycleMatch_1 ? 1'h0 : pendingRegisters_1; // @[Util.scala 151:23 Util.scala 151:36 Util.scala 148:33]
  wire  done_1 = done_cycleMatch_1 | ~pendingRegisters_1; // @[Util.scala 152:16]
  wire  done_cycleMatch_2 = latencies_2 == io_tCycle; // @[Util.scala 150:26]
  wire  _GEN_11 = done_cycleMatch_2 ? 1'h0 : pendingRegisters_2; // @[Util.scala 151:23 Util.scala 151:36 Util.scala 148:33]
  wire  done_2 = done_cycleMatch_2 | ~pendingRegisters_2; // @[Util.scala 152:16]
  wire  done_cycleMatch_3 = latencies_3 == io_tCycle; // @[Util.scala 150:26]
  wire  _GEN_12 = done_cycleMatch_3 ? 1'h0 : pendingRegisters_3; // @[Util.scala 151:23 Util.scala 151:36 Util.scala 148:33]
  wire  done_3 = done_cycleMatch_3 | ~pendingRegisters_3; // @[Util.scala 152:16]
  wire [11:0] _latencies_T_1 = io_tCycle + io_latency; // @[Util.scala 156:43]
  wire  _GEN_30 = 2'h1 == value_1 ? done_1 : done_0; // @[Util.scala 160:26 Util.scala 160:26]
  wire  _GEN_31 = 2'h2 == value_1 ? done_2 : _GEN_30; // @[Util.scala 160:26 Util.scala 160:26]
  wire  _GEN_32 = 2'h3 == value_1 ? done_3 : _GEN_31; // @[Util.scala 160:26 Util.scala 160:26]
  assign ram_id_io_deq_bits_MPORT_addr = value_1;
  assign ram_id_io_deq_bits_MPORT_data = ram_id[ram_id_io_deq_bits_MPORT_addr]; // @[Util.scala 125:16]
  assign ram_id_MPORT_data = io_enq_bits_id;
  assign ram_id_MPORT_addr = value;
  assign ram_id_MPORT_mask = 1'h1;
  assign ram_id_MPORT_en = do_enq & targetFire;
  assign io_enq_ready = ~full; // @[Util.scala 133:19]
  assign io_deq_valid = ~empty & _GEN_32; // @[Util.scala 160:26]
  assign io_deq_bits_id = ram_id_io_deq_bits_MPORT_data; // @[Util.scala 134:15]
  always @(posedge clock) begin
    if(ram_id_MPORT_en & ram_id_MPORT_mask) begin
      ram_id[ram_id_MPORT_addr] <= ram_id_MPORT_data; // @[Util.scala 125:16]
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      value <= 2'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_enq) begin // @[Util.scala 96:17]
        value <= _value_T_1; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      value_1 <= 2'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_deq) begin // @[Util.scala 99:17]
        value_1 <= _value_T_3; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Util.scala 90:27]
      maybe_full <= 1'h0; // @[Util.scala 90:27]
    end else if (targetFire) begin
      if (do_enq != do_deq) begin // @[Util.scala 102:28]
        maybe_full <= do_enq; // @[Util.scala 103:16]
      end
    end
    if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h0 == value) begin // @[Util.scala 156:30]
          latencies_0 <= _latencies_T_1; // @[Util.scala 156:30]
        end
      end
    end
    if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h1 == value) begin // @[Util.scala 156:30]
          latencies_1 <= _latencies_T_1; // @[Util.scala 156:30]
        end
      end
    end
    if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h2 == value) begin // @[Util.scala 156:30]
          latencies_2 <= _latencies_T_1; // @[Util.scala 156:30]
        end
      end
    end
    if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h3 == value) begin // @[Util.scala 156:30]
          latencies_3 <= _latencies_T_1; // @[Util.scala 156:30]
        end
      end
    end
    if (reset & targetFire) begin // @[Util.scala 148:33]
      pendingRegisters_0 <= 1'h0; // @[Util.scala 148:33]
    end else if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h0 == value) begin // @[Util.scala 157:37]
          pendingRegisters_0 <= io_latency != 12'h1; // @[Util.scala 157:37]
        end else begin
          pendingRegisters_0 <= _GEN_9;
        end
      end else begin
        pendingRegisters_0 <= _GEN_9;
      end
    end
    if (reset & targetFire) begin // @[Util.scala 148:33]
      pendingRegisters_1 <= 1'h0; // @[Util.scala 148:33]
    end else if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h1 == value) begin // @[Util.scala 157:37]
          pendingRegisters_1 <= io_latency != 12'h1; // @[Util.scala 157:37]
        end else begin
          pendingRegisters_1 <= _GEN_10;
        end
      end else begin
        pendingRegisters_1 <= _GEN_10;
      end
    end
    if (reset & targetFire) begin // @[Util.scala 148:33]
      pendingRegisters_2 <= 1'h0; // @[Util.scala 148:33]
    end else if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h2 == value) begin // @[Util.scala 157:37]
          pendingRegisters_2 <= io_latency != 12'h1; // @[Util.scala 157:37]
        end else begin
          pendingRegisters_2 <= _GEN_11;
        end
      end else begin
        pendingRegisters_2 <= _GEN_11;
      end
    end
    if (reset & targetFire) begin // @[Util.scala 148:33]
      pendingRegisters_3 <= 1'h0; // @[Util.scala 148:33]
    end else if (targetFire) begin
      if (do_enq) begin // @[Util.scala 155:17]
        if (2'h3 == value) begin // @[Util.scala 157:37]
          pendingRegisters_3 <= io_latency != 12'h1; // @[Util.scala 157:37]
        end else begin
          pendingRegisters_3 <= _GEN_12;
        end
      end else begin
        pendingRegisters_3 <= _GEN_12;
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~do_enq | io_latency != 12'h0 | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: DynamicLatencyPipe only supports latencies > 0\n    at Util.scala:124 assert(!io.enq.fire || io.latency =/= 0.U, \"DynamicLatencyPipe only supports latencies > 0\")\n"
            ); // @[Util.scala 124:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~do_enq | io_latency != 12'h0 | reset) & targetFire) begin
          $fatal; // @[Util.scala 124:9]
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
`ifdef RANDOMIZE_MEM_INIT
  _RAND_0 = {1{`RANDOM}};
  for (initvar = 0; initvar < 4; initvar = initvar+1)
    ram_id[initvar] = _RAND_0[3:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  value = _RAND_1[1:0];
  _RAND_2 = {1{`RANDOM}};
  value_1 = _RAND_2[1:0];
  _RAND_3 = {1{`RANDOM}};
  maybe_full = _RAND_3[0:0];
  _RAND_4 = {1{`RANDOM}};
  latencies_0 = _RAND_4[11:0];
  _RAND_5 = {1{`RANDOM}};
  latencies_1 = _RAND_5[11:0];
  _RAND_6 = {1{`RANDOM}};
  latencies_2 = _RAND_6[11:0];
  _RAND_7 = {1{`RANDOM}};
  latencies_3 = _RAND_7[11:0];
  _RAND_8 = {1{`RANDOM}};
  pendingRegisters_0 = _RAND_8[0:0];
  _RAND_9 = {1{`RANDOM}};
  pendingRegisters_1 = _RAND_9[0:0];
  _RAND_10 = {1{`RANDOM}};
  pendingRegisters_2 = _RAND_10[0:0];
  _RAND_11 = {1{`RANDOM}};
  pendingRegisters_3 = _RAND_11[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module DynamicLatencyPipe_1(
  input        clock,
  input        reset,
  output       io_enq_ready,
  input        io_enq_valid,
  input  [3:0] io_enq_bits_id,
  input        io_deq_ready,
  output       io_deq_valid,
  output [3:0] io_deq_bits_id,
  input        targetFire
);
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
`endif // RANDOMIZE_REG_INIT
  reg [3:0] ram_id [0:3]; // @[Util.scala 125:16]
  wire [3:0] ram_id_io_deq_bits_MPORT_data; // @[Util.scala 125:16]
  wire [1:0] ram_id_io_deq_bits_MPORT_addr; // @[Util.scala 125:16]
  wire [3:0] ram_id_MPORT_data; // @[Util.scala 125:16]
  wire [1:0] ram_id_MPORT_addr; // @[Util.scala 125:16]
  wire  ram_id_MPORT_mask; // @[Util.scala 125:16]
  wire  ram_id_MPORT_en; // @[Util.scala 125:16]
  reg [1:0] value; // @[Counter.scala 60:40]
  reg [1:0] value_1; // @[Counter.scala 60:40]
  reg  maybe_full; // @[Util.scala 90:27]
  wire  ptr_match = value == value_1; // @[Util.scala 92:33]
  wire  empty = ptr_match & ~maybe_full; // @[Util.scala 93:25]
  wire  full = ptr_match & maybe_full; // @[Util.scala 94:24]
  wire [1:0] _value_T_1 = value + 2'h1; // @[Counter.scala 76:24]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 40:37]
  wire [1:0] _value_T_3 = value_1 + 2'h1; // @[Counter.scala 76:24]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 40:37]
  assign ram_id_io_deq_bits_MPORT_addr = value_1;
  assign ram_id_io_deq_bits_MPORT_data = ram_id[ram_id_io_deq_bits_MPORT_addr]; // @[Util.scala 125:16]
  assign ram_id_MPORT_data = io_enq_bits_id;
  assign ram_id_MPORT_addr = value;
  assign ram_id_MPORT_mask = 1'h1;
  assign ram_id_MPORT_en = do_enq & targetFire;
  assign io_enq_ready = ~full; // @[Util.scala 133:19]
  assign io_deq_valid = ~empty; // @[Util.scala 160:19]
  assign io_deq_bits_id = ram_id_io_deq_bits_MPORT_data; // @[Util.scala 134:15]
  always @(posedge clock) begin
    if(ram_id_MPORT_en & ram_id_MPORT_mask) begin
      ram_id[ram_id_MPORT_addr] <= ram_id_MPORT_data; // @[Util.scala 125:16]
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      value <= 2'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_enq) begin // @[Util.scala 96:17]
        value <= _value_T_1; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      value_1 <= 2'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_deq) begin // @[Util.scala 99:17]
        value_1 <= _value_T_3; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Util.scala 90:27]
      maybe_full <= 1'h0; // @[Util.scala 90:27]
    end else if (targetFire) begin
      if (do_enq != do_deq) begin // @[Util.scala 102:28]
        maybe_full <= do_enq; // @[Util.scala 103:16]
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
`ifdef RANDOMIZE_MEM_INIT
  _RAND_0 = {1{`RANDOM}};
  for (initvar = 0; initvar < 4; initvar = initvar+1)
    ram_id[initvar] = _RAND_0[3:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  value = _RAND_1[1:0];
  _RAND_2 = {1{`RANDOM}};
  value_1 = _RAND_2[1:0];
  _RAND_3 = {1{`RANDOM}};
  maybe_full = _RAND_3[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module DRAMBackend(
  input         clock,
  input         reset,
  output        io_newRead_ready,
  input         io_newRead_valid,
  input  [3:0]  io_newRead_bits_id,
  output        io_newWrite_ready,
  input         io_newWrite_valid,
  input  [3:0]  io_newWrite_bits_id,
  input         io_completedRead_ready,
  output        io_completedRead_valid,
  output [3:0]  io_completedRead_bits_id,
  input         io_completedWrite_ready,
  output        io_completedWrite_valid,
  output [3:0]  io_completedWrite_bits_id,
  input  [11:0] io_readLatency,
  input  [11:0] io_tCycle,
  input         targetFire
);
  wire  rQueue_clock;
  wire  rQueue_reset;
  wire  rQueue_io_enq_ready;
  wire  rQueue_io_enq_valid;
  wire [3:0] rQueue_io_enq_bits_id;
  wire  rQueue_io_deq_ready;
  wire  rQueue_io_deq_valid;
  wire [3:0] rQueue_io_deq_bits_id;
  wire [11:0] rQueue_io_latency;
  wire [11:0] rQueue_io_tCycle;
  wire  rQueue_targetFire;
  wire  wQueue_clock;
  wire  wQueue_reset;
  wire  wQueue_io_enq_ready;
  wire  wQueue_io_enq_valid;
  wire [3:0] wQueue_io_enq_bits_id;
  wire  wQueue_io_deq_ready;
  wire  wQueue_io_deq_valid;
  wire [3:0] wQueue_io_deq_bits_id;
  wire  wQueue_targetFire;
  DynamicLatencyPipe rQueue (
    .clock(rQueue_clock),
    .reset(rQueue_reset),
    .io_enq_ready(rQueue_io_enq_ready),
    .io_enq_valid(rQueue_io_enq_valid),
    .io_enq_bits_id(rQueue_io_enq_bits_id),
    .io_deq_ready(rQueue_io_deq_ready),
    .io_deq_valid(rQueue_io_deq_valid),
    .io_deq_bits_id(rQueue_io_deq_bits_id),
    .io_latency(rQueue_io_latency),
    .io_tCycle(rQueue_io_tCycle),
    .targetFire(rQueue_targetFire)
  );
  DynamicLatencyPipe_1 wQueue (
    .clock(wQueue_clock),
    .reset(wQueue_reset),
    .io_enq_ready(wQueue_io_enq_ready),
    .io_enq_valid(wQueue_io_enq_valid),
    .io_enq_bits_id(wQueue_io_enq_bits_id),
    .io_deq_ready(wQueue_io_deq_ready),
    .io_deq_valid(wQueue_io_deq_valid),
    .io_deq_bits_id(wQueue_io_deq_bits_id),
    .targetFire(wQueue_targetFire)
  );
  assign io_newRead_ready = rQueue_io_enq_ready; // @[DramCommon.scala 722:17]
  assign io_newWrite_ready = wQueue_io_enq_ready; // @[DramCommon.scala 724:17]
  assign io_completedRead_valid = rQueue_io_deq_valid; // @[DramCommon.scala 720:20]
  assign io_completedRead_bits_id = rQueue_io_deq_bits_id; // @[DramCommon.scala 720:20]
  assign io_completedWrite_valid = wQueue_io_deq_valid; // @[DramCommon.scala 721:21]
  assign io_completedWrite_bits_id = wQueue_io_deq_bits_id; // @[DramCommon.scala 721:21]
  assign rQueue_clock = clock;
  assign rQueue_reset = reset;
  assign rQueue_io_enq_valid = io_newRead_valid; // @[DramCommon.scala 722:17]
  assign rQueue_io_enq_bits_id = io_newRead_bits_id; // @[DramCommon.scala 722:17]
  assign rQueue_io_deq_ready = io_completedRead_ready; // @[DramCommon.scala 720:20]
  assign rQueue_io_latency = io_readLatency; // @[DramCommon.scala 723:21]
  assign rQueue_io_tCycle = io_tCycle; // @[DramCommon.scala 726:45]
  assign rQueue_targetFire = targetFire;
  assign wQueue_clock = clock;
  assign wQueue_reset = reset;
  assign wQueue_io_enq_valid = io_newWrite_valid; // @[DramCommon.scala 724:17]
  assign wQueue_io_enq_bits_id = io_newWrite_bits_id; // @[DramCommon.scala 724:17]
  assign wQueue_io_deq_ready = io_completedWrite_ready; // @[DramCommon.scala 721:21]
  assign wQueue_targetFire = targetFire;
endmodule