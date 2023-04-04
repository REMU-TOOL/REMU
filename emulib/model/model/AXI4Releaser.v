module AXI4Releaser(
  input         clock,
  input         reset,
  input         io_b_ready,
  output        io_b_valid,
  output [3:0]  io_b_bits_id,
  input         io_r_ready,
  output        io_r_valid,
  output [63:0] io_r_bits_data,
  output        io_r_bits_last,
  output [3:0]  io_r_bits_id,
  output        io_egressReq_b_valid,
  output [3:0]  io_egressReq_b_bits,
  output        io_egressReq_r_valid,
  output [3:0]  io_egressReq_r_bits,
  input  [3:0]  io_egressResp_bBits_id,
  output        io_egressResp_bReady,
  input  [63:0] io_egressResp_rBits_data,
  input         io_egressResp_rBits_last,
  input  [3:0]  io_egressResp_rBits_id,
  output        io_egressResp_rReady,
  output        io_nextRead_ready,
  input         io_nextRead_valid,
  input  [3:0]  io_nextRead_bits_id,
  output        io_nextWrite_ready,
  input         io_nextWrite_valid,
  input  [3:0]  io_nextWrite_bits_id,
  input         targetFire
);
  wire  currentRead_clock;
  wire  currentRead_reset;
  wire  currentRead_io_enq_ready;
  wire  currentRead_io_enq_valid;
  wire  currentRead_io_deq_ready;
  wire  currentRead_io_deq_valid;
  wire  currentRead_targetFire;
  wire  currentWrite_clock;
  wire  currentWrite_reset;
  wire  currentWrite_io_enq_ready;
  wire  currentWrite_io_enq_valid;
  wire  currentWrite_io_deq_ready;
  wire  currentWrite_io_deq_valid;
  wire  currentWrite_targetFire;
  wire  _currentRead_io_deq_ready_T = io_r_ready & io_r_valid; // @[Decoupled.scala 40:37]
  Queue_3 currentRead (
    .clock(currentRead_clock),
    .reset(currentRead_reset),
    .io_enq_ready(currentRead_io_enq_ready),
    .io_enq_valid(currentRead_io_enq_valid),
    .io_deq_ready(currentRead_io_deq_ready),
    .io_deq_valid(currentRead_io_deq_valid),
    .targetFire(currentRead_targetFire)
  );
  Queue_4_0 currentWrite (
    .clock(currentWrite_clock),
    .reset(currentWrite_reset),
    .io_enq_ready(currentWrite_io_enq_ready),
    .io_enq_valid(currentWrite_io_enq_valid),
    .io_deq_ready(currentWrite_io_deq_ready),
    .io_deq_valid(currentWrite_io_deq_valid),
    .targetFire(currentWrite_targetFire)
  );
  assign io_b_valid = currentWrite_io_deq_valid; // @[Util.scala 347:14]
  assign io_b_bits_id = io_egressResp_bBits_id; // @[Util.scala 348:13]
  assign io_r_valid = currentRead_io_deq_valid; // @[Util.scala 339:14]
  assign io_r_bits_data = io_egressResp_rBits_data; // @[Util.scala 340:13]
  assign io_r_bits_last = io_egressResp_rBits_last; // @[Util.scala 340:13]
  assign io_r_bits_id = io_egressResp_rBits_id; // @[Util.scala 340:13]
  assign io_egressReq_b_valid = io_nextWrite_ready & io_nextWrite_valid; // @[Decoupled.scala 40:37]
  assign io_egressReq_b_bits = io_nextWrite_bits_id; // @[Util.scala 346:23]
  assign io_egressReq_r_valid = io_nextRead_ready & io_nextRead_valid; // @[Decoupled.scala 40:37]
  assign io_egressReq_r_bits = io_nextRead_bits_id; // @[Util.scala 338:23]
  assign io_egressResp_bReady = io_b_ready; // @[Util.scala 349:24]
  assign io_egressResp_rReady = io_r_ready; // @[Util.scala 341:24]
  assign io_nextRead_ready = currentRead_io_enq_ready; // @[Decoupled.scala 299:17]
  assign io_nextWrite_ready = currentWrite_io_enq_ready; // @[Decoupled.scala 299:17]
  assign currentRead_clock = clock;
  assign currentRead_reset = reset;
  assign currentRead_io_enq_valid = io_nextRead_valid; // @[Decoupled.scala 297:22]
  assign currentRead_io_deq_ready = _currentRead_io_deq_ready_T & io_r_bits_last; // @[Util.scala 336:34]
  assign currentRead_targetFire = targetFire;
  assign currentWrite_clock = clock;
  assign currentWrite_reset = reset;
  assign currentWrite_io_enq_valid = io_nextWrite_valid; // @[Decoupled.scala 297:22]
  assign currentWrite_io_deq_ready = io_b_ready & io_b_valid; // @[Decoupled.scala 40:37]
  assign currentWrite_targetFire = targetFire;
endmodule