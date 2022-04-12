`timescale 1 ns / 1 ps
`default_nettype none

module EmuReset (
    output reg reset
);

    // TODO: synchronous to clock
    // TODO: specify duration

    reg [63:0] startcycle;

    initial begin
        reset = 0;
        startcycle = $get_init_cycle;
        if (startcycle < 10) begin
            #10 reset = 1;
            #((10-startcycle)*10) reset = 0;
        end
    end

endmodule

`default_nettype wire
