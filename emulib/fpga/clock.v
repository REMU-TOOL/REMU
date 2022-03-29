`timescale 1ns / 1ps
`default_nettype none

(* keep, __emu_directive = {
    "rewrite_clk -ff_clk dut_ff_clk -ram_clk dut_ram_clk dut_clk;",
    "extern dut_ff_clk dut_ram_clk;"
} *)

module EmuClock (
    output wire clock,

    input wire dut_clk
);

    assign clock = dut_clk;

endmodule

`default_nettype wire
