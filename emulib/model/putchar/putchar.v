`timescale 1ns / 1ps

module putchar (
    input           clk,
    input           rst,
    input           valid,
    input   [7:0]   data
);

    (* keep, emu_internal_sig = "CLOCK"         *)  wire model_clk;
    (* keep, emu_internal_sig = "RESET"         *)  wire model_rst;
    //(* keep, emu_internal_sig = "PAUSE"         *)  wire pause;
    //(* keep, emu_internal_sig = "UP_REQ"        *)  wire up_req;
    //(* keep, emu_internal_sig = "DOWN_REQ"      *)  wire down_req;
    //(* keep, emu_internal_sig = "UP_STAT"       *)  wire up_stat;
    //(* keep, emu_internal_sig = "DOWN_STAT"     *)  wire down_stat;
    (* keep, emu_internal_sig = "STALL"         *)  wire stall;

    (* keep, emu_internal_sig = "putchar_valid" *)  wire putchar_valid;
    (* keep, emu_internal_sig = "putchar_ready" *)  wire putchar_ready;
    (* keep, emu_internal_sig = "putchar_data"  *)  wire [7:0] putchar_data;

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

    assign stall = valid_r && !putchar_ready;

    assign putchar_valid = valid_r;
    assign putchar_data = data_r;

endmodule
