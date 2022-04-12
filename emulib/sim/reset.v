`timescale 1 ns / 1 ps
`default_nettype none

module EmuReset (
    output reg reset
);

    // TODO: synchronous to clock
    // TODO: specify duration

    reg [63:0] startcycle, duration;

    initial begin
        startcycle = $get_init_cycle;
        if (startcycle > 10)
            duration = 0;
        else
            duration = (10 - startcycle) * 10;
        reset = 1;
        #duration reset = 0;
    end

endmodule

`default_nettype wire
