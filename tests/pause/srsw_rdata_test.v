`timescale 1 ns / 1 ps

`include "test.vh"

module sim_top();

    reg clk = 0, rst = 1;
    reg pause = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg [63:0] ff_sdi = 0;
    wire [63:0] ff_sdo;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    reg wen = 0, ren = 0;
    reg [1:0] waddr = 0, raddr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata_dut, rdata_ref;

    wire dut_ff_clk, dut_ram_clk;

    ClockGate dut_ff_gate(
        .CLK(clk),
        .EN(!pause || ff_scan),
        .GCLK(dut_ff_clk)
    );

    ClockGate dut_ram_gate(
        .CLK(clk),
        .EN(!pause || ram_scan),
        .GCLK(dut_ram_clk)
    );

    EMU_DUT emu_dut(
        .emu_clk            (clk),
        .emu_ff_se          (ff_scan),
        .emu_ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .emu_ff_do          (ff_sdo),
        .emu_ram_se         (ram_scan),
        .emu_ram_sd         (ram_dir),
        .emu_ram_di         (ram_sdi),
        .emu_ram_do         (ram_sdo),
        .emu_dut_ff_clk     (dut_ff_clk),
        .emu_dut_ram_clk    (dut_ram_clk),
        .emu_dut_rst        (rst),
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
        .EN(!pause),
        .GCLK(ref_clk)
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
        pause = $random;
        wen = $random;
        waddr = $random;
        wdata = $random;
        ren = $random;
        raddr = $random;
    end

    always #10 begin
        $display("%dns: pause=%h rst=%h wen=%h waddr=%h wdata=%h ren=%h raddr=%h rdata_dut=%h rdata_ref=%h",
            $time, pause, rst, wen, waddr, wdata, ren, raddr, rdata_dut, rdata_ref);
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

    `DUMP_VCD

endmodule
