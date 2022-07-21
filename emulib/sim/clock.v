`timescale 1 ns / 1 ps
`default_nettype none

(* keep *)
module EmuClock (
    output reg clock
);

    // TODO: specify cycle

    reg [63:0] runcycle;

    initial begin
        clock = 1;
        forever #5 clock = ~clock;
    end

    initial begin
        if ($value$plusargs("runcycle=%d", runcycle)) begin
            #((runcycle+1)*10) $finish;
        end
    end

endmodule

`default_nettype wire
