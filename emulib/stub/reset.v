`timescale 1 ns / 1 ps

(* emulib_component = "reset" *)
module EmuReset #(
    parameter DURATION_NS = 20
)
(
    output reset
);

`ifdef RECONSTRUCT

    reg [63:0] starttime;
    reg reset_gen = DURATION_NS > 0;

    initial begin
        if (!$value$plusargs("starttime=%d", starttime)) begin
            starttime = 0;
        end
        if (starttime >= DURATION_NS) begin
            reset_gen = 0;
        end
        else begin
            #(DURATION_NS - starttime);
            reset_gen <= 0;
        end
    end

    assign reset = reset_gen;

`endif

endmodule
