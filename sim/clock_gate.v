`timescale 1ns / 1ps

module clock_gate(
    input clk,
    input en,
    output gclk
);

    reg en_latch;
    always @(negedge clk)
        en_latch = en;
    assign gclk = clk & en_latch;

endmodule
