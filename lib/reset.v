`timescale 1 ns / 1 ps

(* emulib_reset *)
module EmuReset #(
    parameter DURATION_NS = 100
)
(
    output reset
);

`ifdef SIMULATION
    reg sim_reset = 1;
    initial #DURATION_NS sim_reset = 0;

    assign reset = sim_reset;
`endif

endmodule
