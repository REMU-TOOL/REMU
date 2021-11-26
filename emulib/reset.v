`timescale 1 ns / 1 ps

(* emulib_reset *)
module EmuReset #(
    parameter DURATION_CYCLES = 100
)
(
    input clock,
    output reset
);

`ifndef EMULIB_TEST

    integer cnt = 0;
    reg reset_gen = 1;

    always @(negedge clk) begin
        cnt = cnt + 1;
        if (cnt >= DURATION_CYCLES)
            reset_gen = 0;
    end

    assign reset = reset_gen;

`endif

endmodule
