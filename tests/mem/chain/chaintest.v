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

    reg ren1 = 0, wen1 = 0, ren2 = 0, wen2 = 0, ren3 = 0, wen3 = 0;
    reg [2:0] raddr1 = 0, waddr1 = 0, raddr2 = 0, waddr2 = 0, raddr3 = 0, waddr3 = 0;
    reg [31:0] wdata1 = 0;
    reg [63:0] wdata2 = 0;
    reg [127:0] wdata3 = 0;
    wire [31:0] rdata1;
    wire [63:0] rdata2;
    wire [127:0] rdata3;

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
        .ren1(ren1),
        .raddr1(raddr1),
        .rdata1(rdata1),
        .wen1(wen1),
        .waddr1(waddr1),
        .wdata1(wdata1),
        .ren2(ren2),
        .raddr2(raddr2),
        .rdata2(rdata2),
        .wen2(wen2),
        .waddr2(waddr2),
        .wdata2(wdata2),
        .ren3(ren3),
        .raddr3(raddr3),
        .rdata3(rdata3),
        .wen3(wen3),
        .waddr3(waddr3),
        .wdata3(wdata3)
    );

    integer i, j;
    reg [31:0] data_save1 [ROUND-1:0][7:0];
    reg [63:0] data_save2 [ROUND-1:0][7:0];
    reg [128:0] data_save3 [ROUND-1:0][7:0];
    reg [31:0] rdata_save1 [ROUND-1:0];
    reg [63:0] rdata_save2 [ROUND-1:0];
    reg [128:0] rdata_save3 [ROUND-1:0];
    reg [`RAM_BIT_COUNT-1:0] scan_save [ROUND-1:0];
    reg [`FF_BIT_COUNT-1:0] ff_scan_save [ROUND-1:0];

    always #5 clk = ~clk;

    initial begin
        #30;
        rst = 0;
        $display("dump checkpoint");
        for (i=0; i<ROUND; i=i+1) begin
            // initialize memory contents
            for (j=0; j<8; j=j+1) begin
                waddr1 = j;
                wdata1 = $random;
                wen1 = 1;
                #10;
                wen1 = 0;
                data_save1[i][j] = wdata1;
                $display("round %0d: mem1[%h]=%h", i, waddr1, wdata1);
            end
            for (j=0; j<8; j=j+1) begin
                waddr2 = j;
                wdata2 = {$random, $random};
                wen2 = 1;
                #10;
                wen2 = 0;
                data_save2[i][j] = wdata2;
                $display("round %0d: mem2[%h]=%h", i, waddr2, wdata2);
            end
            for (j=0; j<8; j=j+1) begin
                waddr3 = j;
                wdata3 = {$random, $random, $random, $random};
                wen3 = 1;
                #10;
                wen3 = 0;
                data_save3[i][j] = wdata3;
                $display("round %0d: mem3[%h]=%h", i, waddr3, wdata3);
            end
            // read addr=1
            ren1 = 1;
            raddr1 = 1;
            #10;
            ren1 = 0;
            rdata_save1[i] = rdata1;
            $display("round %0d: rdata1=%h", i, rdata1);
            ren2 = 1;
            raddr2 = 1;
            #10;
            ren2 = 0;
            rdata_save2[i] = rdata2;
            $display("round %0d: rdata2=%h", i, rdata2);
            ren3 = 1;
            raddr3 = 1;
            #10;
            ren3 = 0;
            rdata_save3[i] = rdata3;
            $display("round %0d: rdata3=%h", i, rdata3);
            // pause
            run_mode = 0; #10; scan_mode = 1;
            ram_scan_reset = 1;
            #10;
            ram_scan_reset = 0;
            // dump ff
            ff_scan = 1;
            ff_dir = 0;
            for (j=0; j<`FF_BIT_COUNT; j=j+1) begin
                // randomize backpressure
                ff_scan = 0;
                while (!ff_scan) begin
                    #10;
                    ff_scan = $random;
                end
                ff_scan_save[i][j] = ff_sdo;
                #10;
            end
            $display("round %0d: ff scan data = %h", i, ff_scan_save[i]);
            ff_scan = 0;
            // dump mem
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
            // pause
            run_mode = 0; #10; scan_mode = 1;
            ram_scan_reset = 1;
            #10;
            ram_scan_reset = 0;
            // load ff
            ff_scan = 1;
            ff_dir = 1;
            for (j=0; j<`FF_BIT_COUNT; j=j+1) begin
                // randomize backpressure
                ff_scan = 0;
                while (!ff_scan) begin
                    #10;
                    ff_scan = $random;
                end
                ff_sdi = ff_scan_save[i][j];
                #10;
            end
            ff_scan = 0;
            // load mem
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
            // compare rdata register
            $display("round %0d: rdata1=%h", i, rdata1);
            if (rdata1 !== rdata_save1[i]) begin
                $display("ERROR: data mismatch");
                $fatal;
            end
            $display("round %0d: rdata2=%h", i, rdata2);
            if (rdata2 !== rdata_save2[i]) begin
                $display("ERROR: data mismatch");
                $fatal;
            end
            $display("round %0d: rdata3=%h", i, rdata3);
            if (rdata3 !== rdata_save3[i]) begin
                $display("ERROR: data mismatch");
                $fatal;
            end
            // compare memory contents
            ren1 = 1;
            for (j=0; j<8; j=j+1) begin
                raddr1 = j;
                #10;
                $display("round %0d: mem1[%h]=%h", i, raddr1, rdata1);
                if (rdata1 !== data_save1[i][j]) begin
                    $display("ERROR: data mismatch");
                    $fatal;
                end
            end
            ren1 = 0;
            ren2 = 1;
            for (j=0; j<8; j=j+1) begin
                raddr2 = j;
                #10;
                $display("round %0d: mem2[%h]=%h", i, raddr2, rdata2);
                if (rdata2 !== data_save2[i][j]) begin
                    $display("ERROR: data mismatch");
                    $fatal;
                end
            end
            ren2 = 0;
            ren3 = 1;
            for (j=0; j<8; j=j+1) begin
                raddr3 = j;
                #10;
                $display("round %0d: mem3[%h]=%h", i, raddr3, rdata3);
                if (rdata3 !== data_save3[i][j]) begin
                    $display("ERROR: data mismatch");
                    $fatal;
                end
            end
            ren3 = 0;
        end
        $display("success");
        $finish;
    end

endmodule
