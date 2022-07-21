`timescale 1ns / 1ps
`default_nettype none

(* keep *)
module EmuDataSource #(
    parameter DATA_WIDTH = 1,
    parameter FIFO_DEPTH = 16
)(
    input  wire                     clk,
    input  wire                     ren,
    output wire [DATA_WIDTH-1:0]    rdata
);

endmodule

`default_nettype wire
