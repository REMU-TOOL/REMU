`timescale 1 ns / 1 ps

module EmuReset (
    output wire reset
);

    EmuResetImp imp (
        .reset(reset)
    );

endmodule
