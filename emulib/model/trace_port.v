`timescale 1ns / 1ps

`include "axi.vh"

(* keep *)
module EmuTracePort #(
    parameter   DATA_WIDTH  = 1
)(
    input  wire                     clk,
    input  wire [DATA_WIDTH-1:0]    data
);

    (* keep *)
    EmuTracePortImp #(
        .DATA_WIDTH (DATA_WIDTH)
    ) imp (
        .clk        (clk),
        .data       (data)
    );

endmodule
