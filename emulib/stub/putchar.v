`resetall
`timescale 1ns / 1ps
`default_nettype none

(* keep, emulib_component = "putchar" *)
module PutCharDevice (
    input  wire         clk,
    input  wire         rst,
    input  wire         valid,
    input  wire [7:0]   data
);

endmodule

`resetall
