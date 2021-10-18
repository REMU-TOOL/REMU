`timescale 1 ns / 1 ps

`include "test.vh"

module sim_top();

    reg clk = 0, rst = 1;
    reg halt = 0;
    reg en = 1;
    reg [31:0] d = 0;
    wire [31:0] q_dut, q_ref;

    \$EMU_DUT emu_dut(
        .\$EMU$CLK          (clk),
        .\$EMU$HALT         (halt),
        .\$EMU$DUT$RESET    (rst),
        .\$EMU$FF$SCAN      (1'd0),
        .\$EMU$FF$SDI       (64'd0),
        .\$EMU$FF$SDO       (),
        .\$EMU$RAM$SCAN     (1'd0),
        .\$EMU$RAM$DIR      (1'd0),
        .\$EMU$RAM$SDI      (64'd0),
        .\$EMU$RAM$SDO      (),
        .en(en),
        .d(d),
        .q(q_dut)
    );

    ffhalt ref(
        .en(en),
        .d(d),
        .q(q_ref)
    );

    always @* force ref.clock.sim_clock = clk & !halt;
    always @* force ref.reset.sim_reset = rst;

    always #5 clk = ~clk;
    always #10 begin
        rst = $random;
        halt = $random;
        en = $random;
        d = $random;
    end

    always #10 begin
        $display("%dns: halt=%h rst=%h en=%h d=%h q_dut=%h q_ref=%h", $time, halt, rst, en, d, q_dut, q_ref);
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
