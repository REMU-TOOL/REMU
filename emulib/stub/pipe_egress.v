`timescale 1ns / 1ps

(* keep *)
module EmuEgressPipe #(
    parameter DATA_WIDTH = 1
)(
    input  wire                     clk,
    input  wire                     valid,
    input  wire [DATA_WIDTH-1:0]    data
);

endmodule
