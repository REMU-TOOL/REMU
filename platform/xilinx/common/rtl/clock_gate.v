`timescale 1ns / 1ps

module clock_gate(
    input clk,
    input en,
    output gclk
);

    BUFGCE u_bufgce (
        .O(gclk),
        .CE(en),
        .I(clk)
    );

endmodule
