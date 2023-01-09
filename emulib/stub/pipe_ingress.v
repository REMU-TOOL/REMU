`timescale 1ns / 1ps

(* keep *)
module EmuIngressPipe #(
    parameter DATA_WIDTH = 1
)(
    input  wire                     clk,
    input  wire                     enable,
    output wire                     valid,
    output wire [DATA_WIDTH-1:0]    data
);

endmodule
