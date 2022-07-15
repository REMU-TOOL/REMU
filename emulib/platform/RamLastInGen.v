`timescale 1ns / 1ps
`default_nettype none

// generate last_i signal for mem scan chain
// delay 1 cycle for scan-out mode to prepare raddr

module RamLastInGen #(
    parameter DEPTH = 0
)(
    input  wire     clk,
    input  wire     ram_sr,
    input  wire     ram_se,
    input  wire     ram_sd,
    output wire     ram_li
);

    // scan in counter

    localparam CNTBITS = $clog2(DEPTH + 1);

    reg [CNTBITS-1:0] in_cnt;
    wire in_full = in_cnt == DEPTH;

    always @(posedge clk)
        if (ram_sr)
            in_cnt <= 0;
        else if (ram_se && !in_full)
            in_cnt <= in_cnt + 1;

    // scan out flag

    reg out_flag;

    always @(posedge clk)
        if (ram_sr)
            out_flag <= 1'b0;
        else if (ram_se)
            out_flag <= 1'b1;

    // posedge capture

    wire start = ram_sd ? in_full : out_flag;
    reg start_r;

    always @(posedge clk)
        if (ram_se)
            start_r <= start;

    assign ram_li = start && !start_r;

endmodule

`default_nettype wire
