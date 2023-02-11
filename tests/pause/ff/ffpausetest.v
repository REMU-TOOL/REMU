`timescale 1 ns / 1 ps

`include "loader.vh"

module sim_top();

    reg clk = 0, rst = 1;
    reg run_mode = 1, scan_mode = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg ff_sdi = 0;
    wire ff_sdo;
    reg ram_scan_reset = 0;
    reg ram_scan = 0, ram_dir = 0;
    reg ram_sdi = 0;
    wire ram_sdo;

    reg en = 1;
    reg [31:0] d = 0;
    wire [31:0] q_dut, q_ref;

    EMU_SYSTEM emu_dut(
        .EMU_HOST_CLK       (clk),
        .EMU_RUN_MODE       (run_mode),
        .EMU_SCAN_MODE      (scan_mode),
        .EMU_FF_SE          (ff_scan),
        .EMU_FF_DI          (ff_dir ? ff_sdi : ff_sdo),
        .EMU_FF_DO          (ff_sdo),
        .EMU_RAM_SR         (ram_scan_reset),
        .EMU_RAM_SE         (ram_scan),
        .EMU_RAM_SD         (ram_dir),
        .EMU_RAM_DI         (ram_sdi),
        .EMU_RAM_DO         (ram_sdo),
        .rst(rst),
        .en(en),
        .d(d),
        .q(q_dut)
    );

    wire ref_clk;

    ClockGate ref_gate(
        .CLK(clk),
        .EN(run_mode),
        .OCLK(ref_clk)
    );

    ffpause ref(
        .clk(ref_clk),
        .rst(rst),
        .en(en),
        .d(d),
        .q(q_ref)
    );

    always #5 clk = ~clk;
    always #10 begin
        rst = $random;
        run_mode = $random;
        en = $random;
        d = $random;
    end

    always #10 begin
        $display("%dns: run_mode=%h rst=%h en=%h d=%h q_dut=%h q_ref=%h", $time, run_mode, rst, en, d, q_dut, q_ref);
        if (q_dut !== q_ref) begin
            $display("ERROR: data mismatch");
            $fatal;
        end
    end

    initial begin
        #3000;
        $display("success");
        $finish;
    end

endmodule
