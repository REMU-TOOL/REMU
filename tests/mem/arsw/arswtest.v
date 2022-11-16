`timescale 1 ns / 1 ps

`include "loader.vh"

module sim_top();

    parameter ROUND = 4;

    reg clk = 0, rst = 1;
    reg run_mode = 1, scan_mode = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg ff_sdi = 0;
    wire ff_sdo;
    reg ram_scan_reset = 0;
    reg ram_scan = 0, ram_dir = 0;
    reg ram_sdi = 0;
    wire ram_sdo;

    reg [5:0] raddr = 0, waddr = 0;
    reg [79:0] wdata;
    reg wen;
    wire [79:0] rdata;

    EMU_SYSTEM emu_dut(
        .EMU_HOST_CLK       (clk),
        .EMU_RUN_MODE       (run_mode),
        .EMU_SCAN_MODE      (scan_mode),
        .EMU_FF_SE          (ff_scan),
        .EMU_FF_DI          (ff_dir ? ff_sdi : ff_sdo),
        .EMU_FF_DO          (ff_sdo),
        .EMU_RAM_SR         (ram_scan_reset),
        .EMU_RAM_SE         (ram_scan),
        .EMU_RAM_SD         (ram_dir),
        .EMU_RAM_DI         (ram_sdi),
        .EMU_RAM_DO         (ram_sdo),
        .raddr(raddr),
        .rdata(rdata),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata)
    );

    integer i, j;
    reg [79:0] data_save [ROUND-1:0][63:0];
    reg [`RAM_BIT_COUNT-1:0] scan_save [ROUND-1:0];

    always #5 clk = ~clk;

    initial begin
        #30;
        rst = 0;
        $display("dump checkpoint");
        for (i=0; i<ROUND; i=i+1) begin
            for (j=0; j<64; j=j+1) begin
                waddr = j;
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
            for (j=0; j<`RAM_BIT_COUNT; j=j+1) begin
                // randomize backpressure
                ram_scan = 0;
                while (!ram_scan) begin
                    #10;
                    ram_scan = $random;
                end
                scan_save[i][j] = ram_sdo;
                #10;
            end
            $display("round %0d: scan data: %h", i, scan_save[i]);
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
            for (j=0; j<`RAM_BIT_COUNT; j=j+1) begin
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
            for (j=0; j<64; j=j+1) begin
                raddr = j;
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
