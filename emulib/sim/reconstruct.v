`timescale 1ns / 1ps

module reconstruct();

    reg [63:0] cycle = 0;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars();
        //$emu_cycle(cycle);
    end

endmodule
