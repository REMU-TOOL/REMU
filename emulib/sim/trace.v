`timescale 1ns / 1ps
`default_nettype none

module EmuTrace #(
    parameter   DATA_WIDTH  = 64
)(
    input  wire                     clk,
    input  wire                     valid,
    input  wire [DATA_WIDTH-1:0]    data
);

endmodule

`default_nettype wire
