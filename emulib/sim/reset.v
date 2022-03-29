`timescale 1 ns / 1 ps
`default_nettype none

module EmuReset (
    output reg reset
);

    real duration;

    initial begin
        reset = 1;
        if (!$value$plusargs("reset_duration=%f", cycle)) begin
            $display("WARNING: reset_duration is not specified");
            duration = 0;
        end
        #(duration) reset = 0;
    end

endmodule

`default_nettype wire
