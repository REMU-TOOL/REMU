`timescale 1 ns / 1 ps

module clock #(
    parameter CYCLE_PERIOD_PS = 10000,
    parameter PHASE_SHIFT_PS = 0
)
(
    output clock,
    output ram_clock
);

    (* keep, emu_internal_sig = "DUT_FF_CLK" *)
    wire _ff_clk;
    (* keep, emu_internal_sig = "DUT_RAM_CLK" *)
    wire _ram_clk;

    assign clock = _ff_clk;
    assign ram_clock = _ram_clk;

endmodule
