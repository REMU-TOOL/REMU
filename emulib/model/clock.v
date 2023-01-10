`timescale 1 ns / 1 ps

module EmuClock (
    output wire clock
);

    EmuClockImp imp (
        .clock(clock)
    );

endmodule
