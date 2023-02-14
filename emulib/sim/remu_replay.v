`timescale 1ns / 1ps

module remu_replay;

    reg [63:0] cycle = 0;

    if (1) begin : internal // use generate if to create an internal scope
        reg global_event = 0;
        reg [512*8-1:0] plusargs_dumpfile;
        reg [63:0] duration;

        initial begin
            if ($value$plusargs("dumpfile=%s", plusargs_dumpfile)) begin
                $dumpfile(plusargs_dumpfile);
                $dumpvars();
            end
        end

        initial begin
            if ($value$plusargs("duration=%d", duration)) begin
                while (duration > 0) @(posedge global_event) duration = duration - 1;
                $finish;
            end
        end
    end

endmodule
