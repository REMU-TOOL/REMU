`include "test.vh"

module sim_top();

    reg clk = 0, rst = 1;
    reg halt = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg [63:0] ff_sdi = 0;
    wire [63:0] ff_sdo;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    reg [2:0] raddr = 0, waddr = 0;
    reg [79:0] wdata = 0;
    reg wen = 0;
    wire [79:0] rdata;

    \$EMU_DUT emu_dut(
        .\$EMU$CLK      (clk),
        .\$EMU$HALT     (halt),
        .\$EMU$FF$SCAN  (ff_scan),
        .\$EMU$FF$SDI   (ff_dir ? ff_sdi : ff_sdo),
        .\$EMU$FF$SDO   (ff_sdo),
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
    reg [79:0] data_save [3:0][7:0];
    reg [79:0] rdata_save [3:0];
    reg [63:0] scan_save [3:0][15:0];
    reg [63:0] ff_scan_save [3:0][1:0];

    always #5 clk = ~clk;

    initial begin
        #30;
        rst = 0;
        $display("dump checkpoint");
        for (i=0; i<4; i=i+1) begin
            // initialize memory contents
            for (j=0; j<8; j=j+1) begin
                waddr = j;
                wdata = {$random, $random, $random};
                wen = 1;
                #10;
                wen = 0;
                data_save[i][j] = wdata;
                $display("round %d: mem[%h]=%h", i, waddr, wdata);
            end
            // read addr=1
            raddr = 1;
            #10;
            rdata_save[i] = rdata;
            $display("round %d: rdata=%h", i, rdata);
            // halt
            halt = 1;
            #10;
            // dump ff
            ff_scan = 1;
            ff_dir = 0;
            for (j=0; j<2; j=j+1) begin
                ff_scan_save[i][j] = ff_sdo;
                $display("round %d: ff scan data %d = %h", i, j, ff_sdo);
                #10;
            end
            ff_scan = 0;
            // dump mem
            ram_scan = 1;
            ram_dir = 0;
            #20;
            for (j=0; j<16; j=j+1) begin
                scan_save[i][j] = ram_sdo;
                $display("round %d: ram scan data %d: %h", i, j, ram_sdo);
                #10;
            end
            ram_scan = 0;
            #10;
            halt = 0;
        end
        #10;
        $display("restore checkpoint");
        for (i=0; i<4; i=i+1) begin
            // halt
            halt = 1;
            #10;
            // load ff
            ff_scan = 1;
            ff_dir = 1;
            for (j=0; j<2; j=j+1) begin
                ff_sdi = ff_scan_save[i][j];
                #10;
            end
            ff_scan = 0;
            // load mem
            ram_scan = 1;
            ram_dir = 1;
            for (j=0; j<16; j=j+1) begin
                ram_sdi = scan_save[i][j];
                #10;
            end
            #10;
            ram_scan = 0;
            #10;
            halt = 0;
            // compare rdata register
            $display("round %d: rdata=%h", i, rdata);
            if (rdata !== rdata_save[i]) begin
                $display("ERROR: data mismatch");
                $fatal;
            end
            // compare memory contents
            for (j=0; j<8; j=j+1) begin
                raddr = j;
                #10;
                $display("round %d: mem[%h]=%h", i, raddr, rdata);
                if (rdata !== data_save[i][j]) begin
                    $display("ERROR: data mismatch");
                    $fatal;
                end
            end
        end
        $display("success");
        $finish;
    end

    `DUMP_VCD

endmodule
