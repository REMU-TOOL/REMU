module IdentityModule(
  output        io_in_aw_ready,
  input         io_in_aw_valid,
  input  [34:0] io_in_aw_bits_addr,
  input  [3:0]  io_in_aw_bits_id,
  output        io_in_w_ready,
  input         io_in_w_valid,
  input         io_in_w_bits_last,
  output        io_in_ar_ready,
  input         io_in_ar_valid,
  input  [34:0] io_in_ar_bits_addr,
  input  [3:0]  io_in_ar_bits_id,
  input         io_out_aw_ready,
  output        io_out_aw_valid,
  output [34:0] io_out_aw_bits_addr,
  output [3:0]  io_out_aw_bits_id,
  input         io_out_w_ready,
  output        io_out_w_valid,
  output        io_out_w_bits_last,
  input         io_out_ar_ready,
  output        io_out_ar_valid,
  output [34:0] io_out_ar_bits_addr,
  output [3:0]  io_out_ar_bits_id
);
  assign io_in_aw_ready = io_out_aw_ready; // @[Lib.scala 460:10]
  assign io_in_w_ready = io_out_w_ready; // @[Lib.scala 460:10]
  assign io_in_ar_ready = io_out_ar_ready; // @[Lib.scala 460:10]
  assign io_out_aw_valid = io_in_aw_valid; // @[Lib.scala 460:10]
  assign io_out_aw_bits_addr = io_in_aw_bits_addr; // @[Lib.scala 460:10]
  assign io_out_aw_bits_id = io_in_aw_bits_id; // @[Lib.scala 460:10]
  assign io_out_w_valid = io_in_w_valid; // @[Lib.scala 460:10]
  assign io_out_w_bits_last = io_in_w_bits_last; // @[Lib.scala 460:10]
  assign io_out_ar_valid = io_in_ar_valid; // @[Lib.scala 460:10]
  assign io_out_ar_bits_addr = io_in_ar_bits_addr; // @[Lib.scala 460:10]
  assign io_out_ar_bits_id = io_in_ar_bits_id; // @[Lib.scala 460:10]
endmodule

module MemoryModelMonitor(
  input        clock,
  input        reset,
  input        axi4_aw_ready,
  input        axi4_aw_valid,
  input  [7:0] axi4_aw_bits_len,
  input        axi4_ar_ready,
  input        axi4_ar_valid,
  input  [7:0] axi4_ar_bits_len,
  input        targetFire
);
  wire  _T = axi4_ar_ready & axi4_ar_valid; // @[Decoupled.scala 40:37]
  wire  _T_7 = axi4_aw_ready & axi4_aw_valid; // @[Decoupled.scala 40:37]
  always @(posedge clock) begin
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T | axi4_ar_bits_len < 8'h8 | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Read burst length exceeds memory-model maximum of 8\n    at Util.scala:750 assert(!axi4.ar.fire || axi4.ar.bits.len < cfg.maxReadLength.U,\n"
            ); // @[Util.scala 750:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T | axi4_ar_bits_len < 8'h8 | reset) & targetFire) begin
          $fatal; // @[Util.scala 750:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~_T_7 | axi4_aw_bits_len < 8'h8 | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Write burst length exceeds memory-model maximum of 8\n    at Util.scala:752 assert(!axi4.aw.fire || axi4.aw.bits.len < cfg.maxWriteLength.U,\n"
            ); // @[Util.scala 752:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~_T_7 | axi4_aw_bits_len < 8'h8 | reset) & targetFire) begin
          $fatal; // @[Util.scala 752:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
endmodule
