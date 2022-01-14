`resetall
`timescale 1ns / 1ps
`default_nettype none

(* keep, emulib_component = "clock" *)
module EmuClock #(
    parameter CYCLE_PERIOD_PS = 10000,
    parameter PHASE_SHIFT_PS = 0
)
(
    output wire clock
);

    (* keep, emu_dut_clk *)
    wire dut_clk;

    assign clock = dut_clk;

endmodule

`resetall
