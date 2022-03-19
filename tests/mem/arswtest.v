`timescale 1 ns / 1 ps

`include "test.vh"

module sim_top();

    parameter ROUND = 4;

    reg clk = 0, rst = 1;
    reg pause = 0;
    reg ff_scan = 0, ff_dir = 0;
    reg [63:0] ff_sdi = 0;
    wire [63:0] ff_sdo;
    reg ram_scan = 0, ram_dir = 0;
    reg [63:0] ram_sdi = 0;
    wire [63:0] ram_sdo;

    reg [5:0] raddr = 0, waddr = 0;
    reg [79:0] wdata;
    reg wen;
    wire [79:0] rdata;

    wire dut_ff_clk, dut_ram_clk;

    ClockGate dut_ff_gate(
        .CLK(clk),
        .EN(!pause || ff_scan),
        .GCLK(dut_ff_clk)
    );

    ClockGate dut_ram_gate(
        .CLK(clk),
        .EN(!pause || ram_scan),
        .GCLK(dut_ram_clk)
    );

    EMU_DUT emu_dut(
        .emu_host_clk       (clk),
        .emu_ff_se          (ff_scan),
        .emu_ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .emu_ff_do          (ff_sdo),
        .emu_ram_se         (ram_scan),
        .emu_ram_sd         (ram_dir),
        .emu_ram_di         (ram_sdi),
        .emu_ram_do         (ram_sdo),
        .emu_dut_ff_clk     (dut_ff_clk),
        .emu_dut_ram_clk    (dut_ram_clk),
        .emu_dut_rst        (rst),
        .raddr(raddr),
        .rdata(rdata),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata)
    );

    integer i, j;
    reg [79:0] data_save [ROUND-1:0][63:0];
    reg [`LOAD_WIDTH-1:0] scan_save [ROUND-1:0][`CHAIN_MEM_WORDS-1:0];

    always #5 clk = ~clk;

    `LOAD_DECLARE

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
                $display("round %d: mem[%h]=%h", i, waddr, wdata);
            end
            pause = 1;
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
            pause = 0;
        end
        #10;
        $display("restore checkpoint");
        for (i=0; i<ROUND; i=i+1) begin
            pause = 1;
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
            pause = 0;
            for (j=0; j<64; j=j+1) begin
                raddr = j;
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
