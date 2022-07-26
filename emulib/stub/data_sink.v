`timescale 1ns / 1ps

(* keep *)
module EmuDataSink #(
    parameter DATA_WIDTH = 1,
    parameter FIFO_DEPTH = 16
)(
    input  wire                     clk,
    input  wire                     wen,
    input  wire [DATA_WIDTH-1:0]    wdata
);

endmodule
