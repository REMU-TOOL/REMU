`timescale 1 ns / 1 ps

`include "test.vh"

module fftest();

    reg clk = 0, rst = 1;
    reg halt = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg [63:0] ff_sdi = 0;
    wire [63:0] ff_sdo;

    reg [63:0] d1 = 0;
    reg [31:0] d2 = 0;
    reg [7:0] d3 = 0;
    reg [79:0] d4 = 0;
    wire [63:0] q1;
    wire [31:0] q2;
    wire [7:0] q3;
    wire [79:0] q4;

    \$EMU_DUT emu_dut(
        .\$EMU$CLK          (clk),
        .\$EMU$HALT         (halt),
        .\$EMU$DUT$RESET    (rst),
        .\$EMU$FF$SCAN      (ff_scan),
        .\$EMU$FF$SDI       (ff_dir ? ff_sdi : ff_sdo),
        .\$EMU$FF$SDO       (ff_sdo),
        .\$EMU$RAM$SCAN     (1'd0),
        .\$EMU$RAM$DIR      (1'd0),
        .\$EMU$RAM$SDI      (64'd0),
        .\$EMU$RAM$SDO      (),
        .d1(d1),
        .d2(d2),
        .d3(d3),
        .d4(d4),
        .q1(q1),
        .q2(q2),
        .q3(q3),
        .q4(q4)
    );

    integer i, j;
    reg [63:0] scandata [3:0] [2:0];
    reg [183:0] d_data [3:0];

    always #5 clk = ~clk;

    initial begin
        #30;
        rst = 0;
        $display("dump checkpoint");
        for (i=0; i<4; i=i+1) begin
            d1 = {$random, $random};
            d2 = $random;
            d3 = $random;
            d4 = {$random, $random, $random};
            $display("round %d: d1=%h d2=%h d3=%h d4=%h", i, d1, d2, d3, d4);
            d_data[i] = {d1, d2, d3, d4};
            #10;
            halt = 1;
            ff_scan = 1;
            ff_dir = 0;
            for (j=0; j<3; j=j+1) begin
                scandata[i][j] = ff_sdo;
                $display("round %d: scan data beat %d = %h", i, j, ff_sdo);
                #10;
            end
            ff_scan = 0;
            halt = 0;
            $display("round %d: q1=%h q2=%h q3=%h q4=%h", i, q1, q2, q3, q4);
            if (d_data[i] !== {q1, q2, q3, q4}) begin
                $display("ERROR: data mismatch while dumping");
                $fatal;
            end
        end
        $display("restore checkpoint");
        for (i=0; i<4; i++) begin
            halt = 1;
            ff_scan = 1;
            ff_dir = 1;
            for (j=0; j<3; j=j+1) begin
                ff_sdi = scandata[i][j];
                $display("round %d: scan data beat %d = %h", i, j, ff_sdi);
                #10;
            end
            ff_scan = 0;
            $display("round %d: q1=%h q2=%h q3=%h q4=%h", i, q1, q2, q3, q4);
            if (d_data[i] !== {q1, q2, q3, q4}) begin
                $display("ERROR: data mismatch after restoring");
                $fatal;
            end
        end
        $display("success");
        $finish;
    end

    `DUMP_VCD

endmodule
