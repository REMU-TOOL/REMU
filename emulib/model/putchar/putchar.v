`resetall
`timescale 1ns / 1ps
`default_nettype none

module putchar (
    input  wire         clk,
    input  wire         rst,
    input  wire         valid,
    input  wire [7:0]   data
);

    //(* keep, emu_intf_port = "clk"              *)  wire model_clk;
    //(* keep, emu_intf_port = "rst"              *)  wire model_rst;
    (* keep, emu_intf_port = "stall_gen"        *)  wire stall_gen;

    (* keep, emu_intf_port = "putchar_valid"    *)  wire putchar_valid;
    (* keep, emu_intf_port = "putchar_ready"    *)  wire putchar_ready;
    (* keep, emu_intf_port = "putchar_data"     *)  wire [7:0] putchar_data;

    reg valid_r;
    reg [7:0] data_r;

    always @(posedge clk)
        if (rst)
            valid_r <= 1'b0;
        else if (valid)
            valid_r <= 1'b1;
        else if (putchar_ready)
            valid_r <= 1'b0;

    always @(posedge clk) 
        data_r <= data;

    assign stall_gen = valid_r && !putchar_ready;

    assign putchar_valid = valid_r;
    assign putchar_data = data_r;

endmodule

`resetall
