`include "test.vh"

module sim_top();

    reg clk = 0, rst = 1;
    reg halt = 0;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    reg [5:0] raddr = 0, waddr = 0;
    reg [79:0] wdata;
    reg wen;
    wire [79:0] rdata;

    \$EMU_DUT emu_dut(
        .\$EMU$CLK      (clk),
        .\$EMU$HALT     (halt),
        .\$EMU$FF$SCAN  (1'd0),
        .\$EMU$FF$SDI   (64'd0),
        .\$EMU$FF$SDO   (),
        .\$EMU$RAM$SCAN (ram_scan),
        .\$EMU$RAM$DIR  (ram_dir),
        .\$EMU$RAM$SDI  (ram_sdi),
        .\$EMU$RAM$SDO  (ram_sdo),
        .rst(rst),
        .raddr(raddr),
        .rdata(rdata),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata)
    );

    integer i, j;
    reg [79:0] data_save [3:0][63:0];
    reg [63:0] scan_save [3:0][127:0];

    always #5 clk = ~clk;

    initial begin
        #30;
        rst = 0;
        $display("dump checkpoint");
        for (i=0; i<4; i=i+1) begin
            for (j=0; j<64; j=j+1) begin
                waddr = j;
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
            for (j=0; j<128; j=j+1) begin
                #10;
                scan_save[i][j] = ram_sdo;
                $display("round %d: scan data %d: %h", i, j, ram_sdo);
            end
            ram_scan = 0;
            #10;
            halt = 0;
        end
        #10;
        $display("restore checkpoint");
        for (i=0; i<4; i=i+1) begin
            halt = 1;
            #10;
            ram_scan = 1;
            ram_dir = 1;
            for (j=0; j<128; j=j+1) begin
                ram_sdi = scan_save[i][j];
                #10;
            end
            #10;
            ram_scan = 0;
            #10;
            halt = 0;
            for (j=0; j<64; j=j+1) begin
                raddr = j;
                #10;
                $display("round %d: mem[%h]=%h", i, raddr, rdata);
                if (rdata != data_save[i][j]) begin
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
