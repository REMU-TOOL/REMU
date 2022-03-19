`resetall
`timescale 1ns / 1ps
`default_nettype none

(* keep, __emu_directive = {
    "extern host_clk;",
    "extern host_rst;",
    "extern target_fire;",
    "extern stall;",
    "extern putchar_valid;",
    "extern putchar_ready;",
    "extern putchar_data;"
} *)

module EmuPutChar (
    input  wire         clk,
    input  wire         rst,
    input  wire         valid,
    input  wire [7:0]   data,

    input  wire         host_clk,
    input  wire         host_rst,
    input  wire         target_fire,
    output wire         stall,
    output wire         putchar_valid,
    input  wire         putchar_ready,
    output wire [7:0]   putchar_data
);

    wire decoupled_rst      = target_fire && rst;
    wire decoupled_valid    = target_fire && valid;

    wire fifo_iready;

    emulib_fifo #(
        .WIDTH      (8),
        .DEPTH      (16)
    ) char_fifo (
        .clk        (host_clk),
        .rst        (host_rst || decoupled_rst),
        .ivalid     (decoupled_valid),
        .iready     (fifo_iready),
        .idata      (data),
        .ovalid     (putchar_valid),
        .oready     (putchar_ready),
        .odata      (putchar_data)
    );

    assign stall = valid && !fifo_iready;

endmodule

`resetall
