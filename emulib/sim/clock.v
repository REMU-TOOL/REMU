`timescale 1 ns / 1 ps
`default_nettype none

module EmuClock (
    output reg clock
);

    real cycle;

    initial begin
        clock = 1;
        if (!$value$plusargs("clock_cycle=%f", cycle)) begin
            $display("WARNING: clock_cycle is not specified");
            cycle = 10;
        end
        forever #(cycle/2) clock = ~clock;
    end

endmodule

`default_nettype wire
