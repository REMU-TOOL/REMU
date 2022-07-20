`timescale 1 ns / 1 ps

`include "loader.vh"

module sim_top();

    reg clk = 0, rst = 1;
    reg run_mode = 1, scan_mode = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg [63:0] ff_sdi = 0;
    wire [63:0] ff_sdo;
    reg ram_scan_reset = 0;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    reg wen = 0, ren = 0;
    reg [1:0] waddr = 0, raddr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata_dut, rdata_ref;

    EMU_SYSTEM emu_dut(
        .host_clk       (clk),
        .run_mode       (run_mode),
        .scan_mode      (scan_mode),
        .ff_se          (ff_scan),
        .ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .ff_do          (ff_sdo),
        .ram_sr         (ram_scan_reset),
        .ram_se         (ram_scan),
        .ram_sd         (ram_dir),
        .ram_di         (ram_sdi),
        .ram_do         (ram_sdo),
        .reset_reset    (rst),
        .target_wen(wen),
        .target_waddr(waddr),
        .target_wdata(wdata),
        .target_ren(ren),
        .target_raddr(raddr),
        .target_rdata(rdata_dut)
    );

    wire ref_clk;

    ClockGate ref_gate(
        .CLK(clk),
        .EN(run_mode),
        .OCLK(ref_clk)
    );

    srsw_rdata ref(
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata),
        .ren(ren),
        .raddr(raddr),
        .rdata(rdata_ref)
    );

    assign ref.clock.clock = ref_clk;
    assign ref.reset.reset = rst;

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
