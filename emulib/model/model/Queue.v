module Queue_3(
  input   clock,
  input   reset,
  output  io_enq_ready,
  input   io_enq_valid,
  input   io_deq_ready,
  output  io_deq_valid,
  input   targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg  maybe_full; // @[Decoupled.scala 221:27]
  wire  empty = ~maybe_full; // @[Decoupled.scala 224:28]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 40:37]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 40:37]
  assign io_enq_ready = io_deq_ready | empty; // @[Decoupled.scala 254:25 Decoupled.scala 254:40 Decoupled.scala 241:16]
  assign io_deq_valid = ~empty; // @[Decoupled.scala 240:19]
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[Decoupled.scala 221:27]
      maybe_full <= 1'h0; // @[Decoupled.scala 221:27]
    end else if (targetFire) begin
      if (do_enq != do_deq) begin // @[Decoupled.scala 236:28]
        maybe_full <= do_enq; // @[Decoupled.scala 237:16]
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
  maybe_full = _RAND_0[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Queue_4_0(
  input   clock,
  input   reset,
  output  io_enq_ready,
  input   io_enq_valid,
  input   io_deq_ready,
  output  io_deq_valid,
  input   targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT
  reg  maybe_full; // @[Decoupled.scala 221:27]
  wire  empty = ~maybe_full; // @[Decoupled.scala 224:28]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 40:37]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 40:37]
  assign io_enq_ready = io_deq_ready | empty; // @[Decoupled.scala 254:25 Decoupled.scala 254:40 Decoupled.scala 241:16]
  assign io_deq_valid = ~empty; // @[Decoupled.scala 240:19]
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[Decoupled.scala 221:27]
      maybe_full <= 1'h0; // @[Decoupled.scala 221:27]
    end else if (targetFire) begin
      if (do_enq != do_deq) begin // @[Decoupled.scala 236:28]
        maybe_full <= do_enq; // @[Decoupled.scala 237:16]
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
  maybe_full = _RAND_0[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Queue_15_0(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [3:0]  io_enq_bits_xaction_id,
  input         io_enq_bits_xaction_isWrite,
  input  [34:0] io_enq_bits_addr,
  input         io_deq_ready,
  output        io_deq_valid,
  output [3:0]  io_deq_bits_xaction_id,
  output        io_deq_bits_xaction_isWrite,
  output [34:0] io_deq_bits_addr,
  input         targetFire
);
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [63:0] _RAND_2;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
`endif // RANDOMIZE_REG_INIT
  reg [3:0] ram_xaction_id [0:7]; // @[Decoupled.scala 218:16]
  wire [3:0] ram_xaction_id_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire [2:0] ram_xaction_id_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire [3:0] ram_xaction_id_MPORT_data; // @[Decoupled.scala 218:16]
  wire [2:0] ram_xaction_id_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_xaction_id_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_xaction_id_MPORT_en; // @[Decoupled.scala 218:16]
  reg  ram_xaction_isWrite [0:7]; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire [2:0] ram_xaction_isWrite_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_MPORT_data; // @[Decoupled.scala 218:16]
  wire [2:0] ram_xaction_isWrite_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_MPORT_en; // @[Decoupled.scala 218:16]
  reg [34:0] ram_addr [0:7]; // @[Decoupled.scala 218:16]
  wire [34:0] ram_addr_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire [2:0] ram_addr_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire [34:0] ram_addr_MPORT_data; // @[Decoupled.scala 218:16]
  wire [2:0] ram_addr_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_addr_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_addr_MPORT_en; // @[Decoupled.scala 218:16]
  reg [2:0] enq_ptr_value; // @[Counter.scala 60:40]
  reg [2:0] deq_ptr_value; // @[Counter.scala 60:40]
  reg  maybe_full; // @[Decoupled.scala 221:27]
  wire  ptr_match = enq_ptr_value == deq_ptr_value; // @[Decoupled.scala 223:33]
  wire  empty = ptr_match & ~maybe_full; // @[Decoupled.scala 224:25]
  wire  full = ptr_match & maybe_full; // @[Decoupled.scala 225:24]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 40:37]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 40:37]
  wire [2:0] _value_T_1 = enq_ptr_value + 3'h1; // @[Counter.scala 76:24]
  wire [2:0] _value_T_3 = deq_ptr_value + 3'h1; // @[Counter.scala 76:24]
  assign ram_xaction_id_io_deq_bits_MPORT_addr = deq_ptr_value;
  assign ram_xaction_id_io_deq_bits_MPORT_data = ram_xaction_id[ram_xaction_id_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_xaction_id_MPORT_data = io_enq_bits_xaction_id;
  assign ram_xaction_id_MPORT_addr = enq_ptr_value;
  assign ram_xaction_id_MPORT_mask = 1'h1;
  assign ram_xaction_id_MPORT_en = do_enq & targetFire;
  assign ram_xaction_isWrite_io_deq_bits_MPORT_addr = deq_ptr_value;
  assign ram_xaction_isWrite_io_deq_bits_MPORT_data = ram_xaction_isWrite[ram_xaction_isWrite_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_xaction_isWrite_MPORT_data = io_enq_bits_xaction_isWrite;
  assign ram_xaction_isWrite_MPORT_addr = enq_ptr_value;
  assign ram_xaction_isWrite_MPORT_mask = 1'h1;
  assign ram_xaction_isWrite_MPORT_en = do_enq & targetFire;
  assign ram_addr_io_deq_bits_MPORT_addr = deq_ptr_value;
  assign ram_addr_io_deq_bits_MPORT_data = ram_addr[ram_addr_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_addr_MPORT_data = io_enq_bits_addr;
  assign ram_addr_MPORT_addr = enq_ptr_value;
  assign ram_addr_MPORT_mask = 1'h1;
  assign ram_addr_MPORT_en = do_enq & targetFire;
  assign io_enq_ready = ~full; // @[Decoupled.scala 241:19]
  assign io_deq_valid = ~empty; // @[Decoupled.scala 240:19]
  assign io_deq_bits_xaction_id = ram_xaction_id_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  assign io_deq_bits_xaction_isWrite = ram_xaction_isWrite_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  assign io_deq_bits_addr = ram_addr_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  always @(posedge clock) begin
    if(ram_xaction_id_MPORT_en & ram_xaction_id_MPORT_mask) begin
      ram_xaction_id[ram_xaction_id_MPORT_addr] <= ram_xaction_id_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if(ram_xaction_isWrite_MPORT_en & ram_xaction_isWrite_MPORT_mask) begin
      ram_xaction_isWrite[ram_xaction_isWrite_MPORT_addr] <= ram_xaction_isWrite_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if(ram_addr_MPORT_en & ram_addr_MPORT_mask) begin
      ram_addr[ram_addr_MPORT_addr] <= ram_addr_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      enq_ptr_value <= 3'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_enq) begin // @[Decoupled.scala 229:17]
        enq_ptr_value <= _value_T_1; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      deq_ptr_value <= 3'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_deq) begin // @[Decoupled.scala 233:17]
        deq_ptr_value <= _value_T_3; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Decoupled.scala 221:27]
      maybe_full <= 1'h0; // @[Decoupled.scala 221:27]
    end else if (targetFire) begin
      if (do_enq != do_deq) begin // @[Decoupled.scala 236:28]
        maybe_full <= do_enq; // @[Decoupled.scala 237:16]
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
  for (initvar = 0; initvar < 8; initvar = initvar+1)
    ram_xaction_id[initvar] = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  for (initvar = 0; initvar < 8; initvar = initvar+1)
    ram_xaction_isWrite[initvar] = _RAND_1[0:0];
  _RAND_2 = {2{`RANDOM}};
  for (initvar = 0; initvar < 8; initvar = initvar+1)
    ram_addr[initvar] = _RAND_2[34:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_3 = {1{`RANDOM}};
  enq_ptr_value = _RAND_3[2:0];
  _RAND_4 = {1{`RANDOM}};
  deq_ptr_value = _RAND_4[2:0];
  _RAND_5 = {1{`RANDOM}};
  maybe_full = _RAND_5[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
module Queue_17_0(
  input        clock,
  input        reset,
  output       io_enq_ready,
  input        io_enq_valid,
  input  [6:0] io_enq_bits,
  input        io_deq_ready,
  output       io_deq_valid,
  output [6:0] io_deq_bits,
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
  reg [6:0] ram [0:3]; // @[Decoupled.scala 218:16]
  wire [6:0] ram_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire [1:0] ram_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire [6:0] ram_MPORT_data; // @[Decoupled.scala 218:16]
  wire [1:0] ram_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_MPORT_en; // @[Decoupled.scala 218:16]
  reg [1:0] enq_ptr_value; // @[Counter.scala 60:40]
  reg [1:0] deq_ptr_value; // @[Counter.scala 60:40]
  reg  maybe_full; // @[Decoupled.scala 221:27]
  wire  ptr_match = enq_ptr_value == deq_ptr_value; // @[Decoupled.scala 223:33]
  wire  empty = ptr_match & ~maybe_full; // @[Decoupled.scala 224:25]
  wire  full = ptr_match & maybe_full; // @[Decoupled.scala 225:24]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 40:37]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 40:37]
  wire [1:0] _value_T_1 = enq_ptr_value + 2'h1; // @[Counter.scala 76:24]
  wire [1:0] _value_T_3 = deq_ptr_value + 2'h1; // @[Counter.scala 76:24]
  assign ram_io_deq_bits_MPORT_addr = deq_ptr_value;
  assign ram_io_deq_bits_MPORT_data = ram[ram_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_MPORT_data = io_enq_bits;
  assign ram_MPORT_addr = enq_ptr_value;
  assign ram_MPORT_mask = 1'h1;
  assign ram_MPORT_en = do_enq & targetFire;
  assign io_enq_ready = ~full; // @[Decoupled.scala 241:19]
  assign io_deq_valid = ~empty; // @[Decoupled.scala 240:19]
  assign io_deq_bits = ram_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  always @(posedge clock) begin
    if(ram_MPORT_en & ram_MPORT_mask) begin
      ram[ram_MPORT_addr] <= ram_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      enq_ptr_value <= 2'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_enq) begin // @[Decoupled.scala 229:17]
        enq_ptr_value <= _value_T_1; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Counter.scala 60:40]
      deq_ptr_value <= 2'h0; // @[Counter.scala 60:40]
    end else if (targetFire) begin
      if (do_deq) begin // @[Decoupled.scala 233:17]
        deq_ptr_value <= _value_T_3; // @[Counter.scala 76:15]
      end
    end
    if (reset & targetFire) begin // @[Decoupled.scala 221:27]
      maybe_full <= 1'h0; // @[Decoupled.scala 221:27]
    end else if (targetFire) begin
      if (do_enq != do_deq) begin // @[Decoupled.scala 236:28]
        maybe_full <= do_enq; // @[Decoupled.scala 237:16]
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
    ram[initvar] = _RAND_0[6:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_1 = {1{`RANDOM}};
  enq_ptr_value = _RAND_1[1:0];
  _RAND_2 = {1{`RANDOM}};
  deq_ptr_value = _RAND_2[1:0];
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

module Queue_16_0(
  input         clock,
  input         reset,
  output        io_enq_ready,
  input         io_enq_valid,
  input  [3:0]  io_enq_bits_xaction_id,
  input         io_enq_bits_xaction_isWrite,
  input  [25:0] io_enq_bits_rowAddr,
  input  [2:0]  io_enq_bits_bankAddr,
  input  [1:0]  io_enq_bits_rankAddr,
  input         io_deq_ready,
  output        io_deq_valid,
  output [3:0]  io_deq_bits_xaction_id,
  output        io_deq_bits_xaction_isWrite,
  output [25:0] io_deq_bits_rowAddr,
  output [2:0]  io_deq_bits_bankAddr,
  output [1:0]  io_deq_bits_rankAddr,
  input         targetFire
);
`ifdef RANDOMIZE_MEM_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_5;
`endif // RANDOMIZE_REG_INIT
  reg [3:0] ram_xaction_id [0:0]; // @[Decoupled.scala 218:16]
  wire [3:0] ram_xaction_id_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_xaction_id_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire [3:0] ram_xaction_id_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_xaction_id_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_xaction_id_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_xaction_id_MPORT_en; // @[Decoupled.scala 218:16]
  reg  ram_xaction_isWrite [0:0]; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_xaction_isWrite_MPORT_en; // @[Decoupled.scala 218:16]
  reg [25:0] ram_rowAddr [0:0]; // @[Decoupled.scala 218:16]
  wire [25:0] ram_rowAddr_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_rowAddr_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire [25:0] ram_rowAddr_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_rowAddr_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_rowAddr_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_rowAddr_MPORT_en; // @[Decoupled.scala 218:16]
  reg [2:0] ram_bankAddr [0:0]; // @[Decoupled.scala 218:16]
  wire [2:0] ram_bankAddr_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_bankAddr_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire [2:0] ram_bankAddr_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_bankAddr_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_bankAddr_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_bankAddr_MPORT_en; // @[Decoupled.scala 218:16]
  reg [1:0] ram_rankAddr [0:0]; // @[Decoupled.scala 218:16]
  wire [1:0] ram_rankAddr_io_deq_bits_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_rankAddr_io_deq_bits_MPORT_addr; // @[Decoupled.scala 218:16]
  wire [1:0] ram_rankAddr_MPORT_data; // @[Decoupled.scala 218:16]
  wire  ram_rankAddr_MPORT_addr; // @[Decoupled.scala 218:16]
  wire  ram_rankAddr_MPORT_mask; // @[Decoupled.scala 218:16]
  wire  ram_rankAddr_MPORT_en; // @[Decoupled.scala 218:16]
  reg  maybe_full; // @[Decoupled.scala 221:27]
  wire  empty = ~maybe_full; // @[Decoupled.scala 224:28]
  wire  do_enq = io_enq_ready & io_enq_valid; // @[Decoupled.scala 40:37]
  wire  do_deq = io_deq_ready & io_deq_valid; // @[Decoupled.scala 40:37]
  assign ram_xaction_id_io_deq_bits_MPORT_addr = 1'h0;
  assign ram_xaction_id_io_deq_bits_MPORT_data = ram_xaction_id[ram_xaction_id_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_xaction_id_MPORT_data = io_enq_bits_xaction_id;
  assign ram_xaction_id_MPORT_addr = 1'h0;
  assign ram_xaction_id_MPORT_mask = 1'h1;
  assign ram_xaction_id_MPORT_en = do_enq & targetFire;
  assign ram_xaction_isWrite_io_deq_bits_MPORT_addr = 1'h0;
  assign ram_xaction_isWrite_io_deq_bits_MPORT_data = ram_xaction_isWrite[ram_xaction_isWrite_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_xaction_isWrite_MPORT_data = io_enq_bits_xaction_isWrite;
  assign ram_xaction_isWrite_MPORT_addr = 1'h0;
  assign ram_xaction_isWrite_MPORT_mask = 1'h1;
  assign ram_xaction_isWrite_MPORT_en = do_enq & targetFire;
  assign ram_rowAddr_io_deq_bits_MPORT_addr = 1'h0;
  assign ram_rowAddr_io_deq_bits_MPORT_data = ram_rowAddr[ram_rowAddr_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_rowAddr_MPORT_data = io_enq_bits_rowAddr;
  assign ram_rowAddr_MPORT_addr = 1'h0;
  assign ram_rowAddr_MPORT_mask = 1'h1;
  assign ram_rowAddr_MPORT_en = do_enq & targetFire;
  assign ram_bankAddr_io_deq_bits_MPORT_addr = 1'h0;
  assign ram_bankAddr_io_deq_bits_MPORT_data = ram_bankAddr[ram_bankAddr_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_bankAddr_MPORT_data = io_enq_bits_bankAddr;
  assign ram_bankAddr_MPORT_addr = 1'h0;
  assign ram_bankAddr_MPORT_mask = 1'h1;
  assign ram_bankAddr_MPORT_en = do_enq & targetFire;
  assign ram_rankAddr_io_deq_bits_MPORT_addr = 1'h0;
  assign ram_rankAddr_io_deq_bits_MPORT_data = ram_rankAddr[ram_rankAddr_io_deq_bits_MPORT_addr]; // @[Decoupled.scala 218:16]
  assign ram_rankAddr_MPORT_data = io_enq_bits_rankAddr;
  assign ram_rankAddr_MPORT_addr = 1'h0;
  assign ram_rankAddr_MPORT_mask = 1'h1;
  assign ram_rankAddr_MPORT_en = do_enq & targetFire;
  assign io_enq_ready = io_deq_ready | empty; // @[Decoupled.scala 254:25 Decoupled.scala 254:40 Decoupled.scala 241:16]
  assign io_deq_valid = ~empty; // @[Decoupled.scala 240:19]
  assign io_deq_bits_xaction_id = ram_xaction_id_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  assign io_deq_bits_xaction_isWrite = ram_xaction_isWrite_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  assign io_deq_bits_rowAddr = ram_rowAddr_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  assign io_deq_bits_bankAddr = ram_bankAddr_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  assign io_deq_bits_rankAddr = ram_rankAddr_io_deq_bits_MPORT_data; // @[Decoupled.scala 242:15]
  always @(posedge clock) begin
    if(ram_xaction_id_MPORT_en & ram_xaction_id_MPORT_mask) begin
      ram_xaction_id[ram_xaction_id_MPORT_addr] <= ram_xaction_id_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if(ram_xaction_isWrite_MPORT_en & ram_xaction_isWrite_MPORT_mask) begin
      ram_xaction_isWrite[ram_xaction_isWrite_MPORT_addr] <= ram_xaction_isWrite_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if(ram_rowAddr_MPORT_en & ram_rowAddr_MPORT_mask) begin
      ram_rowAddr[ram_rowAddr_MPORT_addr] <= ram_rowAddr_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if(ram_bankAddr_MPORT_en & ram_bankAddr_MPORT_mask) begin
      ram_bankAddr[ram_bankAddr_MPORT_addr] <= ram_bankAddr_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if(ram_rankAddr_MPORT_en & ram_rankAddr_MPORT_mask) begin
      ram_rankAddr[ram_rankAddr_MPORT_addr] <= ram_rankAddr_MPORT_data; // @[Decoupled.scala 218:16]
    end
    if (reset & targetFire) begin // @[Decoupled.scala 221:27]
      maybe_full <= 1'h0; // @[Decoupled.scala 221:27]
    end else if (targetFire) begin
      if (do_enq != do_deq) begin // @[Decoupled.scala 236:28]
        maybe_full <= do_enq; // @[Decoupled.scala 237:16]
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
  for (initvar = 0; initvar < 1; initvar = initvar+1)
    ram_xaction_id[initvar] = _RAND_0[3:0];
  _RAND_1 = {1{`RANDOM}};
  for (initvar = 0; initvar < 1; initvar = initvar+1)
    ram_xaction_isWrite[initvar] = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  for (initvar = 0; initvar < 1; initvar = initvar+1)
    ram_rowAddr[initvar] = _RAND_2[25:0];
  _RAND_3 = {1{`RANDOM}};
  for (initvar = 0; initvar < 1; initvar = initvar+1)
    ram_bankAddr[initvar] = _RAND_3[2:0];
  _RAND_4 = {1{`RANDOM}};
  for (initvar = 0; initvar < 1; initvar = initvar+1)
    ram_rankAddr[initvar] = _RAND_4[1:0];
`endif // RANDOMIZE_MEM_INIT
`ifdef RANDOMIZE_REG_INIT
  _RAND_5 = {1{`RANDOM}};
  maybe_full = _RAND_5[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
