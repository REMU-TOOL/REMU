`timescale 1ns / 1ps

module clock_gate(
    input clk,
    input en,
    output gclk
);

`ifdef ULTRASCALE
    BUFGCE #(.CE_TYPE("SYNC")) u_bufgce (
        .O(gclk),
        .CE(en),
        .I(clk)
    );
`else
    reg en_latch;
    always @(negedge clk)
        en_latch = en;
    assign gclk = clk & en_latch;
`endif

endmodule
