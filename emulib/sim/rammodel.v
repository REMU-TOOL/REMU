`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"

module EmuRam #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h10000,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input  wire                     clk,
    input  wire                     rst,

    `AXI4_SLAVE_IF              (s_axi,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)

);

endmodule

`default_nettype wire
