`timescale 1ns / 1ps

`include "loader.vh"

module reconstruct();

    parameter CYCLE = 10;

    reg clk = 1, rst = 1, en = 0;

    always #(CYCLE/2) clk = ~clk;

    emu_top u_emu_top();

    assign u_emu_top.clock.clock = clk & en;
    assign u_emu_top.reset.reset = rst;

    reg [63:0] start_cycle, run_cycle, cycle;

    always @(posedge clk) begin
        if (cycle >= start_cycle + run_cycle) begin
            $finish;
        end
        cycle = cycle + 1;
    end

    always @(negedge clk) begin
        if (cycle + 1 >= u_emu_top.reset.DURATION_CYCLES) begin
            rst = 0;
        end
    end

    reg [`LOAD_WIDTH-1:0] data [`CHAIN_FF_WORDS+`CHAIN_MEM_WORDS-1:0];
    reg [1023:0] checkpoint, dumpfile;

    `LOAD_DECLARE

    initial begin
        if (!$value$plusargs("startcycle=%d", start_cycle)) begin
            $display("ERROR: startcycle not specified");
            $finish;
        end
        if (!$value$plusargs("runcycle=%d", run_cycle)) begin
            $display("ERROR: runcycle not specified");
            $finish;
        end
        if (!$value$plusargs("checkpoint=%s", checkpoint)) begin
            $display("ERROR: checkpoint not specified");
            $finish;
        end
        if (!$value$plusargs("dumpfile=%s", dumpfile)) begin
            $display("ERROR: dumpfile not specified");
            $finish;
        end
        $readmemh(checkpoint, data);
        `LOAD_FF(data, 0, u_emu_top);
        `LOAD_MEM(data, `CHAIN_FF_WORDS, u_emu_top);
        cycle = start_cycle;
        $dumpfile(dumpfile);
        $dumpvars();
        #(CYCLE/2);
        en = 1;
    end

endmodule
