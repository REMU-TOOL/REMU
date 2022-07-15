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

    reg [5:0] raddr = 0, waddr = 0;
    reg [79:0] wdata;
    reg wen;
    wire [79:0] rdata;

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
        .target_raddr(raddr),
        .target_rdata(rdata),
        .target_wen(wen),
        .target_waddr(waddr),
        .target_wdata(wdata)
    );

    integer i, j;
    reg [79:0] data_save [ROUND-1:0][31:0];
    reg [`LOAD_MEM_WIDTH-1:0] scan_save [ROUND-1:0][`CHAIN_MEM_WORDS-1:0];

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
                $display("round %0d: mem[%h]=%h", i, waddr, wdata);
            end
            run_mode = 0; #10; scan_mode = 1;
            ram_scan_reset = 1;
            #10;
            ram_scan_reset = 0;
            ram_scan = 1;
            ram_dir = 0;
            #20;
            for (j=0; j<`CHAIN_MEM_WORDS; j=j+1) begin
                // randomize backpressure
                ram_scan = 0;
                while (!ram_scan) begin
                    #10;
                    ram_scan = $random;
                end
                scan_save[i][j] = ram_sdo;
                $display("round %0d: scan data %h: %h", i, j, ram_sdo);
                #10;
            end
            ram_scan = 0;
            #10;
            scan_mode = 0; #10; run_mode = 1;
        end
        #10;
        $display("restore checkpoint");
        for (i=0; i<ROUND; i=i+1) begin
            run_mode = 0; #10; scan_mode = 1;
            ram_scan_reset = 1;
            #10;
            ram_scan_reset = 0;
            ram_scan = 1;
            ram_dir = 1;
            for (j=0; j<`CHAIN_MEM_WORDS; j=j+1) begin
                // randomize backpressure
                ram_scan = 0;
                while (!ram_scan) begin
                    #10;
                    ram_scan = $random;
                end
                ram_sdi = scan_save[i][j];
                #10;
            end
            #10;
            ram_scan = 0;
            #10;
            scan_mode = 0; #10; run_mode = 1;
            for (j=0; j<32; j=j+1) begin
                raddr = j + 32;
                #10;
                $display("round %0d: mem[%h]=%h", i, raddr, rdata);
                if (rdata !== data_save[i][j]) begin
                    $display("ERROR: data mismatch after restoring");
                    $fatal;
                end
            end
        end
        $display("success");
        $finish;
    end

endmodule
