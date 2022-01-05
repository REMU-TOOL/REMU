`resetall
`timescale 1ns / 1ps
`default_nettype none

module clock #(
    parameter CYCLE_PERIOD_PS = 10000,
    parameter PHASE_SHIFT_PS = 0
)
(
    output wire clock,
    output wire ram_clock
);

    (* keep, emu_intf_port = "dut_ff_clk" *)
    wire _ff_clk;
    (* keep, emu_intf_port = "dut_ram_clk" *)
    wire _ram_clk;

    assign clock = _ff_clk;
    assign ram_clock = _ram_clk;

endmodule

`resetall
