`timescale 1ns / 1ps

module ClockGate(
    input CLK,
    input EN,
    output GCLK
);

    reg en_latch;
    always @(negedge CLK)
        en_latch = EN;
    assign GCLK = CLK & en_latch;

endmodule
