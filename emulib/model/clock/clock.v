`resetall
`timescale 1ns / 1ps
`default_nettype none

module clock #(
    parameter CYCLE_PERIOD_PS = 10000,
    parameter PHASE_SHIFT_PS = 0
)
(
    output wire clock
);

    (* keep, emu_intf_port = "dut_clk" *)
    wire dut_clk;

    assign clock = dut_clk;

endmodule

`resetall
