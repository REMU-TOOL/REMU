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

    reg en = 1;
    reg [31:0] d = 0;
    wire [31:0] q_dut, q_ref;

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
        .\$EMU$CLK          (clk),
        .\$EMU$FF$SE        (ff_scan),
        .\$EMU$FF$DI        (ff_dir ? ff_sdi : ff_sdo),
        .\$EMU$FF$DO        (ff_sdo),
        .\$EMU$RAM$SE       (ram_scan),
        .\$EMU$RAM$SD       (ram_dir),
        .\$EMU$RAM$DI       (ram_sdi),
        .\$EMU$RAM$DO       (ram_sdo),
        .\$EMU$DUT$FF$CLK   (dut_ff_clk),
        .\$EMU$DUT$RAM$CLK  (dut_ram_clk),
        .\$EMU$DUT$RST      (rst),
        .en(en),
        .d(d),
        .q(q_dut)
    );

    wire ref_clk;

    ClockGate ref_gate(
        .CLK(clk),
        .EN(!pause),
        .GCLK(ref_clk)
    );

    ffpause ref(
        .en(en),
        .d(d),
        .q(q_ref)
    );

    assign ref.clock.clock = ref_clk;
    assign ref.reset.reset = rst;

    always #5 clk = ~clk;
    always #10 begin
        rst = $random;
        pause = $random;
        en = $random;
        d = $random;
    end

    always #10 begin
        $display("%dns: pause=%h rst=%h en=%h d=%h q_dut=%h q_ref=%h", $time, pause, rst, en, d, q_dut, q_ref);
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

    `DUMP_VCD

endmodule
