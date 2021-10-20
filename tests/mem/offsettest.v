`timescale 1 ns / 1 ps

`include "test.vh"

module sim_top();

    parameter ROUND = 4;

    reg clk = 0, rst = 1;
    reg halt = 0;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    reg [5:0] raddr = 0, waddr = 0;
    reg [79:0] wdata;
    reg wen;
    wire [79:0] rdata;

    EMU_DUT emu_dut(
        .\$EMU$CLK          (clk),
        .\$EMU$HALT         (halt),
        .\$EMU$DUT$RESET    (rst),
        .\$EMU$FF$SCAN      (1'd0),
        .\$EMU$FF$SDI       (64'd0),
        .\$EMU$FF$SDO       (),
        .\$EMU$RAM$SCAN     (ram_scan),
        .\$EMU$RAM$DIR      (ram_dir),
        .\$EMU$RAM$SDI      (ram_sdi),
        .\$EMU$RAM$SDO      (ram_sdo),
        .raddr(raddr),
        .rdata(rdata),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata)
    );

    integer i, j;
    reg [79:0] data_save [ROUND-1:0][31:0];
    reg [`LOAD_WIDTH-1:0] scan_save [ROUND-1:0][`CHAIN_MEM_WORDS-1:0];

    always #5 clk = ~clk;

    `LOAD_DECLARE

    initial begin
        #30;
        rst = 0;
        $display("dump checkpoint");
        for (i=0; i<ROUND; i=i+1) begin
            for (j=0; j<32; j=j+1) begin
                waddr = j + 32;
                wdata = {$random, $random, $random};
                wen = 1;
                #10;
                wen = 0;
                data_save[i][j] = wdata;
                $display("round %d: mem[%h]=%h", i, waddr, wdata);
            end
            halt = 1;
            #10;
            ram_scan = 1;
            ram_dir = 0;
            #20;
            for (j=0; j<`CHAIN_MEM_WORDS; j=j+1) begin
                scan_save[i][j] = ram_sdo;
                $display("round %d: scan data %d: %h", i, j, ram_sdo);
                #10;
            end
            ram_scan = 0;
            #10;
            halt = 0;
        end
        #10;
        $display("restore checkpoint");
        for (i=0; i<ROUND; i=i+1) begin
            halt = 1;
            #10;
            ram_scan = 1;
            ram_dir = 1;
            for (j=0; j<`CHAIN_MEM_WORDS; j=j+1) begin
                ram_sdi = scan_save[i][j];
                #10;
            end
            #10;
            ram_scan = 0;
            #10;
            halt = 0;
            for (j=0; j<32; j=j+1) begin
                raddr = j + 32;
                #10;
                $display("round %d: mem[%h]=%h", i, raddr, rdata);
                if (rdata !== data_save[i][j]) begin
                    $display("ERROR: data mismatch while dumping");
                    $fatal;
                end
            end
        end
        $display("success");
        $finish;
    end

    `DUMP_VCD

endmodule
