`timescale 1ns / 1ps

module ClockGate(
    input CLK,
    input EN,
    output OCLK
);

    reg en_latch;
    always @(CLK or EN)
        if (~CLK)
            en_latch = EN;
    assign OCLK = CLK & en_latch;

endmodule
