module UnifiedFIFOXactionScheduler(
  input         clock,
  input         reset,
  output        io_req_aw_ready,
  input         io_req_aw_valid,
  input  [34:0] io_req_aw_bits_addr,
  input  [3:0]  io_req_aw_bits_id,
  output        io_req_w_ready,
  input         io_req_w_valid,
  input         io_req_w_bits_last,
  output        io_req_ar_ready,
  input         io_req_ar_valid,
  input  [34:0] io_req_ar_bits_addr,
  input  [3:0]  io_req_ar_bits_id,
  input         io_nextXaction_ready,
  output        io_nextXaction_valid,
  output [3:0]  io_nextXaction_bits_xaction_id,
  output        io_nextXaction_bits_xaction_isWrite,
  output [34:0] io_nextXaction_bits_addr,
  input  [10:0] io_pendingWReq,
  input  [10:0] io_pendingAWReq,
  input         targetFire
);
  wire  transactionQueue_clock;
  wire  transactionQueue_reset;
  wire  transactionQueue_io_enq_ready;
  wire  transactionQueue_io_enq_valid;
  wire [3:0] transactionQueue_io_enq_bits_xaction_id;
  wire  transactionQueue_io_enq_bits_xaction_isWrite;
  wire [34:0] transactionQueue_io_enq_bits_addr;
  wire  transactionQueue_io_deq_ready;
  wire  transactionQueue_io_deq_valid;
  wire [3:0] transactionQueue_io_deq_bits_xaction_id;
  wire  transactionQueue_io_deq_bits_xaction_isWrite;
  wire [34:0] transactionQueue_io_deq_bits_addr;
  wire  transactionQueue_targetFire;
  wire  transactionQueueArb_clock;
  wire  transactionQueueArb_io_in_0_ready;
  wire  transactionQueueArb_io_in_0_valid;
  wire [3:0] transactionQueueArb_io_in_0_bits_xaction_id;
  wire [34:0] transactionQueueArb_io_in_0_bits_addr;
  wire  transactionQueueArb_io_in_1_ready;
  wire  transactionQueueArb_io_in_1_valid;
  wire [3:0] transactionQueueArb_io_in_1_bits_xaction_id;
  wire [34:0] transactionQueueArb_io_in_1_bits_addr;
  wire  transactionQueueArb_io_out_ready;
  wire  transactionQueueArb_io_out_valid;
  wire [3:0] transactionQueueArb_io_out_bits_xaction_id;
  wire  transactionQueueArb_io_out_bits_xaction_isWrite;
  wire [34:0] transactionQueueArb_io_out_bits_addr;
  wire  transactionQueueArb_io_chosen;
  wire  transactionQueueArb_targetFire;
  wire  SatUpDownCounter_clock;
  wire  SatUpDownCounter_reset;
  wire  SatUpDownCounter_io_inc;
  wire  SatUpDownCounter_io_dec;
  wire [3:0] SatUpDownCounter_io_value;
  wire  SatUpDownCounter_io_full;
  wire  SatUpDownCounter_io_empty;
  wire  SatUpDownCounter_targetFire;
  wire  _T = io_req_w_ready & io_req_w_valid; // @[Decoupled.scala 40:37]
  wire  _T_2 = io_nextXaction_ready & io_nextXaction_valid; // @[Decoupled.scala 40:37]
  wire  _T_6 = ~io_nextXaction_bits_xaction_isWrite | ~SatUpDownCounter_io_empty; // @[TransactionSchedulers.scala 58:43]
  Queue_15_0 transactionQueue (
    .clock(transactionQueue_clock),
    .reset(transactionQueue_reset),
    .io_enq_ready(transactionQueue_io_enq_ready),
    .io_enq_valid(transactionQueue_io_enq_valid),
    .io_enq_bits_xaction_id(transactionQueue_io_enq_bits_xaction_id),
    .io_enq_bits_xaction_isWrite(transactionQueue_io_enq_bits_xaction_isWrite),
    .io_enq_bits_addr(transactionQueue_io_enq_bits_addr),
    .io_deq_ready(transactionQueue_io_deq_ready),
    .io_deq_valid(transactionQueue_io_deq_valid),
    .io_deq_bits_xaction_id(transactionQueue_io_deq_bits_xaction_id),
    .io_deq_bits_xaction_isWrite(transactionQueue_io_deq_bits_xaction_isWrite),
    .io_deq_bits_addr(transactionQueue_io_deq_bits_addr),
    .targetFire(transactionQueue_targetFire)
  );
  RRArbiter_0 transactionQueueArb (
    .rst(reset),
    .clock(transactionQueueArb_clock),
    .io_in_0_ready(transactionQueueArb_io_in_0_ready),
    .io_in_0_valid(transactionQueueArb_io_in_0_valid),
    .io_in_0_bits_xaction_id(transactionQueueArb_io_in_0_bits_xaction_id),
    .io_in_0_bits_addr(transactionQueueArb_io_in_0_bits_addr),
    .io_in_1_ready(transactionQueueArb_io_in_1_ready),
    .io_in_1_valid(transactionQueueArb_io_in_1_valid),
    .io_in_1_bits_xaction_id(transactionQueueArb_io_in_1_bits_xaction_id),
    .io_in_1_bits_addr(transactionQueueArb_io_in_1_bits_addr),
    .io_out_ready(transactionQueueArb_io_out_ready),
    .io_out_valid(transactionQueueArb_io_out_valid),
    .io_out_bits_xaction_id(transactionQueueArb_io_out_bits_xaction_id),
    .io_out_bits_xaction_isWrite(transactionQueueArb_io_out_bits_xaction_isWrite),
    .io_out_bits_addr(transactionQueueArb_io_out_bits_addr),
    .io_chosen(transactionQueueArb_io_chosen),
    .targetFire(transactionQueueArb_targetFire)
  );
  SatUpDownCounter_8 SatUpDownCounter (
    .clock(SatUpDownCounter_clock),
    .reset(SatUpDownCounter_reset),
    .io_inc(SatUpDownCounter_io_inc),
    .io_dec(SatUpDownCounter_io_dec),
    .io_value(SatUpDownCounter_io_value),
    .io_full(SatUpDownCounter_io_full),
    .io_empty(SatUpDownCounter_io_empty),
    .targetFire(SatUpDownCounter_targetFire)
  );
  assign io_req_aw_ready = transactionQueueArb_io_in_1_ready; // @[TransactionSchedulers.scala 39:19]
  //assign io_req_w_ready = io_pendingWReq <= io_pendingAWReq; // @[TransactionSchedulers.scala 47:36]
  assign io_req_w_ready = io_pendingWReq <= 1; // @[TransactionSchedulers.scala 47:36]
  assign io_req_ar_ready = transactionQueueArb_io_in_0_ready; // @[TransactionSchedulers.scala 34:19]
  assign io_nextXaction_valid = transactionQueue_io_deq_valid & _T_6; // @[Misc.scala 25:53]
  assign io_nextXaction_bits_xaction_id = transactionQueue_io_deq_bits_xaction_id; // @[TransactionSchedulers.scala 61:18]
  assign io_nextXaction_bits_xaction_isWrite = transactionQueue_io_deq_bits_xaction_isWrite; // @[TransactionSchedulers.scala 61:18]
  assign io_nextXaction_bits_addr = transactionQueue_io_deq_bits_addr; // @[TransactionSchedulers.scala 61:18]
  assign transactionQueue_clock = clock;
  assign transactionQueue_reset = reset;
  assign transactionQueue_io_enq_valid = transactionQueueArb_io_out_valid; // @[TransactionSchedulers.scala 43:27]
  assign transactionQueue_io_enq_bits_xaction_id = transactionQueueArb_io_out_bits_xaction_id; // @[TransactionSchedulers.scala 43:27]
  assign transactionQueue_io_enq_bits_xaction_isWrite = transactionQueueArb_io_out_bits_xaction_isWrite; // @[TransactionSchedulers.scala 43:27]
  assign transactionQueue_io_enq_bits_addr = transactionQueueArb_io_out_bits_addr; // @[TransactionSchedulers.scala 43:27]
  assign transactionQueue_io_deq_ready = io_nextXaction_ready & _T_6; // @[Misc.scala 25:53]
  assign transactionQueue_targetFire = targetFire;
  assign transactionQueueArb_clock = clock;
  assign transactionQueueArb_io_in_0_valid = io_req_ar_valid; // @[TransactionSchedulers.scala 33:38]
  assign transactionQueueArb_io_in_0_bits_xaction_id = io_req_ar_bits_id; // @[Util.scala 274:17 Util.scala 275:10]
  assign transactionQueueArb_io_in_0_bits_addr = io_req_ar_bits_addr; // @[TransactionSchedulers.scala 36:42]
  assign transactionQueueArb_io_in_1_valid = io_req_aw_valid; // @[TransactionSchedulers.scala 38:38]
  assign transactionQueueArb_io_in_1_bits_xaction_id = io_req_aw_bits_id; // @[Util.scala 274:17 Util.scala 275:10]
  assign transactionQueueArb_io_in_1_bits_addr = io_req_aw_bits_addr; // @[TransactionSchedulers.scala 41:42]
  assign transactionQueueArb_io_out_ready = transactionQueue_io_enq_ready; // @[TransactionSchedulers.scala 43:27]
  assign transactionQueueArb_targetFire = targetFire;
  assign SatUpDownCounter_clock = clock;
  assign SatUpDownCounter_reset = reset;
  assign SatUpDownCounter_io_inc = _T & io_req_w_bits_last; // @[TransactionSchedulers.scala 51:40]
  assign SatUpDownCounter_io_dec = _T_2 & io_nextXaction_bits_xaction_isWrite; // @[TransactionSchedulers.scala 52:46]
  assign SatUpDownCounter_targetFire = targetFire;
endmodule

module RRArbiter_0(
  input 	rst,
  input         clock,
  output        io_in_0_ready,
  input         io_in_0_valid,
  input  [3:0]  io_in_0_bits_xaction_id,
  input  [34:0] io_in_0_bits_addr,
  output        io_in_1_ready,
  input         io_in_1_valid,
  input  [3:0]  io_in_1_bits_xaction_id,
  input  [34:0] io_in_1_bits_addr,
  input         io_out_ready,
  output        io_out_valid,
  output [3:0]  io_out_bits_xaction_id,
  output        io_out_bits_xaction_isWrite,
  output [34:0] io_out_bits_addr,
  output        io_chosen,
  input         targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
`endif // RANDOMIZE_REG_INIT

  wire  _ctrl_validMask_grantMask_lastGrant_T = io_out_ready & io_out_valid; // @[Decoupled.scala 40:37]
  reg  lastGrant; // @[Reg.scala 15:16]
  wire  grantMask_1 = 1'h1 > lastGrant; // @[Arbiter.scala 67:49]
  wire  validMask_1 = io_in_1_valid & grantMask_1; // @[Arbiter.scala 68:75]
  wire  ctrl_2 = ~validMask_1; // @[Arbiter.scala 31:78]
  wire  ctrl_3 = ~(validMask_1 | io_in_0_valid); // @[Arbiter.scala 31:78]
  wire  _T_3 = grantMask_1 | ctrl_3; // @[Arbiter.scala 72:50]
  wire  _GEN_13 = io_in_0_valid ? 1'h0 : 1'h1; // @[Arbiter.scala 77:27 Arbiter.scala 77:36]
  assign io_in_0_ready = ctrl_2 & io_out_ready; // @[Arbiter.scala 60:21]
  assign io_in_1_ready = _T_3 & io_out_ready; // @[Arbiter.scala 60:21]
  assign io_out_valid = io_chosen ? io_in_1_valid : io_in_0_valid; // @[Arbiter.scala 41:16 Arbiter.scala 41:16]
  assign io_out_bits_xaction_id = io_chosen ? io_in_1_bits_xaction_id : io_in_0_bits_xaction_id; // @[Arbiter.scala 41:16 Arbiter.scala 41:16]
  assign io_out_bits_xaction_isWrite = io_chosen; // @[Arbiter.scala 41:16 Arbiter.scala 41:16]
  assign io_out_bits_addr = io_chosen ? io_in_1_bits_addr : io_in_0_bits_addr; // @[Arbiter.scala 41:16 Arbiter.scala 41:16]
  assign io_chosen = validMask_1 | _GEN_13; // @[Arbiter.scala 79:25 Arbiter.scala 79:34]
  always @(posedge clock) begin
    if(rst)
    	lastGrant <= 0;
    else if (targetFire) begin
      if (_ctrl_validMask_grantMask_lastGrant_T) begin // @[Reg.scala 16:19]
        lastGrant <= io_chosen; // @[Reg.scala 16:23]
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
  lastGrant = _RAND_0[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
