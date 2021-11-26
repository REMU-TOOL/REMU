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

    reg [63:0] cnt;
    reg reset_gen = DURATION_CYCLES > 0;

    // workaround to access current cycle count
    initial begin
        if ($value$plusargs("startcycle=%d", cnt)) begin
            if (cnt >= DURATION_CYCLES) reset_gen = 0;
        end
        else begin
            cnt = 0;
        end
    end

    always @(posedge clock) begin
        cnt = cnt + 1;
        if (cnt >= DURATION_CYCLES) reset_gen <= 0;
    end

    assign reset = reset_gen;

`endif

endmodule
