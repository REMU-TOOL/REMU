`timescale 1 ns / 1 ps

(* keep, emulib_component = "clock" *)
module EmuClock #(
    parameter CYCLE_PERIOD_PS = 10000,
    parameter PHASE_SHIFT_PS = 0
)
(
    output clock
);

`ifdef RECONSTRUCT

    reg clock_gen = 0;

    initial begin
        #(PHASE_SHIFT_PS/1000);
        forever clock_gen = #(CYCLE_PERIOD_PS/2000) ~clock_gen;
    end

    assign clock = clock_gen;

`endif

endmodule
