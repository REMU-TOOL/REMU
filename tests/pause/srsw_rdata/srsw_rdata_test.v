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

    reg wen = 0, ren = 0;
    reg [1:0] waddr = 0, raddr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata_dut, rdata_ref;

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
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata),
        .ren(ren),
        .raddr(raddr),
        .rdata(rdata_dut)
    );

    wire ref_clk;

    ClockGate ref_gate(
        .CLK(clk),
        .EN(run_mode),
        .OCLK(ref_clk)
    );

    srsw_rdata ref(
        .clk(ref_clk),
        .rst(rst),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata),
        .ren(ren),
        .raddr(raddr),
        .rdata(rdata_ref)
    );

    always #5 clk = ~clk;
    always #10 begin
        rst = $random;
        run_mode = $random;
        wen = $random;
        waddr = $random;
        wdata = $random;
        ren = $random;
        raddr = $random;
    end

    always #10 begin
        $display("%dns: run_mode=%h rst=%h wen=%h waddr=%h wdata=%h ren=%h raddr=%h rdata_dut=%h rdata_ref=%h",
            $time, run_mode, rst, wen, waddr, wdata, ren, raddr, rdata_dut, rdata_ref);
        if (rdata_dut !== rdata_ref) begin
            $display("ERROR: data mismatch");
            $fatal;
        end
    end

    initial begin
        #5000;
        $display("success");
        $finish;
    end

endmodule
