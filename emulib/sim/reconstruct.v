`timescale 1ns / 1ps

module reconstruct();

    reg [63:0] cycle;
    reg [512*8-1:0] __plusargs_dumpfile;

    initial begin
        if ($value$plusargs("dumpfile=%s", __plusargs_dumpfile)) begin
            $dumpfile(__plusargs_dumpfile);
            $dumpvars();
        end
        $cycle_sig(cycle);
    end

endmodule
