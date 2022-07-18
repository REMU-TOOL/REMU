`timescale 1ns / 1ps
`default_nettype none

(* keep *)
module EmuClock (
    output wire clock
);

    (* __emu_user_clk *)
    wire dut_clk;
    assign clock = dut_clk;

endmodule

`default_nettype wire
