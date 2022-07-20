`timescale 1 ns / 1 ps

`include "loader.vh"

module sim_top();

    parameter ROUND = 4;

    reg clk = 0, rst = 1;
    reg run_mode = 1, scan_mode = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg [63:0] ff_sdi = 0;
    wire [63:0] ff_sdo;
    reg ram_scan_reset = 0;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    reg [63:0] d1 = 0;
    reg [31:0] d2 = 0;
    reg [7:0] d3 = 0;
    reg [79:0] d4 = 0;
    wire [63:0] q1;
    wire [31:0] q2;
    wire [7:0] q3;
    wire [79:0] q4;

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
        .target_d1(d1),
        .target_d2(d2),
        .target_d3(d3),
        .target_d4(d4),
        .target_q1(q1),
        .target_q2(q2),
        .target_q3(q3),
        .target_q4(q4)
    );

    integer i, j;
    reg [`LOAD_FF_WIDTH-1:0] scandata [ROUND-1:0] [`CHAIN_FF_WORDS-1:0];
    reg [183:0] d_data [ROUND-1:0];

    always #5 clk = ~clk;

    `LOAD_DECLARE

    initial begin
        #30;
        rst = 0;
        $display("dump checkpoint");
        for (i=0; i<ROUND; i=i+1) begin
            d1 = {$random, $random};
            d2 = $random;
            d3 = $random;
            d4 = {$random, $random, $random};
            $display("round %0d: d1=%h d2=%h d3=%h d4=%h", i, d1, d2, d3, d4);
            d_data[i] = {d1, d2, d3, d4};
            #10;
            run_mode = 0; #10; scan_mode = 1;
            ff_scan = 1;
            ff_dir = 0;
            for (j=0; j<`CHAIN_FF_WORDS; j=j+1) begin
                // randomize backpressure
                ff_scan = 0;
                while (!ff_scan) begin
                    #10;
                    ff_scan = $random;
                end
                scandata[i][j] = ff_sdo;
                $display("round %0d: scan data beat %0d = %h", i, j, ff_sdo);
                #10;
            end
            ff_scan = 0;
            scan_mode = 0; #10; run_mode = 1;
            $display("round %0d: q1=%h q2=%h q3=%h q4=%h", i, q1, q2, q3, q4);
            if (d_data[i] !== {q1, q2, q3, q4}) begin
                $display("ERROR: data mismatch while dumping");
                $fatal;
            end
        end
        $display("restore checkpoint");
        for (i=0; i<ROUND; i++) begin
            run_mode = 0; #10; scan_mode = 1;
            ff_scan = 1;
            ff_dir = 1;
            for (j=0; j<`CHAIN_FF_WORDS; j=j+1) begin
                // randomize backpressure
                ff_scan = 0;
                while (!ff_scan) begin
                    #10;
                    ff_scan = $random;
                end
                ff_sdi = scandata[i][j];
                $display("round %0d: scan data beat %0d = %h", i, j, ff_sdi);
                #10;
            end
            ff_scan = 0;
            $display("round %0d: q1=%h q2=%h q3=%h q4=%h", i, q1, q2, q3, q4);
            if (d_data[i] !== {q1, q2, q3, q4}) begin
                $display("ERROR: data mismatch after restoring");
                $fatal;
            end
        end
        $display("success");
        $finish;
    end

endmodule
