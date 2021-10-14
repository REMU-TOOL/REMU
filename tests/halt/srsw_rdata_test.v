`include "test.vh"

module sim_top();

    reg clk = 0, rst = 1;
    reg halt = 0;
    reg wen = 0, ren = 0;
    reg [1:0] waddr = 0, raddr = 0;
    reg [31:0] wdata = 0;
    wire [31:0] rdata_dut, rdata_ref;

    \$EMU_DUT emu_dut(
        .\$EMU$CLK      (clk),
        .\$EMU$HALT     (halt),
        .\$EMU$FF$SCAN  (1'd0),
        .\$EMU$FF$SDI   (64'd0),
        .\$EMU$FF$SDO   (),
        .\$EMU$RAM$SCAN (1'd0),
        .\$EMU$RAM$DIR  (1'd0),
        .\$EMU$RAM$SDI  (64'd0),
        .\$EMU$RAM$SDO  (),
        .rst(rst),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata),
        .ren(ren),
        .raddr(raddr),
        .rdata(rdata_dut)
    );

    srsw_rdata ref(
        .clk(clk & !halt),
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
        halt = $random;
        wen = $random;
        waddr = $random;
        wdata = $random;
        ren = $random;
        raddr = $random;
    end

    always #10 begin
        $display("%dns: halt=%h rst=%h wen=%h waddr=%h wdata=%h ren=%h raddr=%h rdata_dut=%h rdata_ref=%h",
            $time, halt, rst, wen, waddr, wdata, ren, raddr, rdata_dut, rdata_ref);
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
