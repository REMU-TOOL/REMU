`timescale 1 ns / 1 ps

(* emulib_clock *)
module EmuClock #(
    parameter CYCLE_PERIOD_NS = 10,
    parameter PHASE_SHIFT_NS = 0
)
(
    output clock
);

`ifndef EMULIB_TEST

    reg clock_gen = 0;

    initial begin
        #(PHASE_SHIFT_NS);
        forever clock_gen = #(CYCLE_PERIOD_NS/2) ~clock_gen;
    end

    assign clock = clock_gen;

`endif

endmodule
