`timescale 1 ns / 1 ps

(* emulib_clock *)
module EmuClock #(
    parameter FREQUENCY_MHZ = 100
)
(
    output clock
);

`ifdef SIMULATION
    reg sim_clock = 0;
    always #(1000/FREQUENCY_MHZ/2) sim_clock = ~sim_clock;

    assign clock = sim_clock;
`endif

endmodule
