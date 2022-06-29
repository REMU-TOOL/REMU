`timescale 1ns / 1ps

module ClockGate(
    input CLK,
    input EN,
    output OCLK
);

    BUFGCE u_bufgce (
        .O(OCLK),
        .CE(EN),
        .I(CLK)
    );

endmodule
