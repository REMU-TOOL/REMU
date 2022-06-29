`timescale 1 ns / 1 ps

`include "loader.vh"

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
        .OCLK(dut_ff_clk)
    );

    ClockGate dut_ram_gate(
        .CLK(clk),
        .EN(!pause || ram_scan),
        .OCLK(dut_ram_clk)
    );

    EMU_DUT emu_dut(
        .emu_host_clk       (clk),
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
        .en(en),
        .d(d),
        .q(q_dut)
    );

    wire ref_clk;

    ClockGate ref_gate(
        .CLK(clk),
        .EN(!pause),
        .OCLK(ref_clk)
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

endmodule
