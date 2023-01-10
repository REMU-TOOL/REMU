`timescale 1 ns / 1 ps

(* keep *)
module EmuClockImp (
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
