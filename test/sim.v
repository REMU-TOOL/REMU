`timescale 1 ns / 1 ns

module sim_ram #(
    parameter WIDTH = 32,
    parameter DEPTH = 1024,
    parameter AWIDTH = $clog2(DEPTH)
)(
    input clk,
    input wen1,
    input [AWIDTH-1:0] waddr1,
    input [WIDTH-1:0] wdata1,
    input [WIDTH/8-1:0] wstrb1,
    input wen2,
    input [AWIDTH-1:0] waddr2,
    input [WIDTH-1:0] wdata2,
    input [WIDTH/8-1:0] wstrb2,
    input [AWIDTH-1:0] raddr1,
    output [WIDTH-1:0] rdata1,
    input [AWIDTH-1:0] raddr2,
    output [WIDTH-1:0] rdata2
);

    reg [31:0] mem [1023:0];

    integer i;
    always @(posedge clk) begin
        for (i=0; i<WIDTH/8; i=i+1) if (wen1 && wstrb1[i]) mem[waddr1][i*8+:8] <= wdata1[i*8+:8];
        for (i=0; i<WIDTH/8; i=i+1) if (wen2 && wstrb2[i]) mem[waddr2][i*8+:8] <= wdata2[i*8+:8];
    end

    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];

    initial begin
        $readmemh("initmem.txt", mem);
    end

endmodule

module sim_top();

    reg clk, rst;
    always #5 clk = ~clk;

    reg emu_halt, emu_ram_rreq, emu_ram_wreq, emu_ram_rready, emu_ram_wvalid;
    reg [11:0] emu_raddr, emu_waddr, emu_ram_rid, emu_ram_wid;
    reg [63:0] emu_wen, emu_wdata, emu_ram_wdata;
    wire [63:0] emu_rdata, emu_ram_rdata;
    wire emu_ram_rvalid, emu_ram_wready, emu_ram_rdone, emu_ram_wdone;

    wire [31:0] PC;
    wire  [31:0] Instruction;
    wire [31:0] Address;
    wire MemWrite;
    wire [31:0] Write_data;
    wire [3:0] Write_strb;
    wire MemRead;
    wire [31:0] Read_data;

    mips_cpu u_cpu ( 
        .clk                (clk),
        .rst                (rst),
        .PC                 (PC),
        .Instruction        (Instruction),
        .Address            (Address),
        .MemWrite           (MemWrite),
        .Write_data         (Write_data),
        .Write_strb         (Write_strb),
        .MemRead            (MemRead),
        .Read_data          (Read_data),
        .\$EMU$RESET        (rst),
        .\$EMU$HALT         (emu_halt),
        .\$EMU$RADDR        (emu_raddr),
        .\$EMU$RDATA        (emu_rdata),
        .\$EMU$WADDR        (emu_waddr),
        .\$EMU$WDATA        (emu_wdata),
        .\$EMU$WEN          (emu_wen),
        .\$EMU$RAM$RDATA    (emu_ram_rdata),
        .\$EMU$RAM$RDONE    (emu_ram_rdone),
        .\$EMU$RAM$RID      (emu_ram_rid),
        .\$EMU$RAM$RREADY   (emu_ram_rready),
        .\$EMU$RAM$RREQ     (emu_ram_rreq),
        .\$EMU$RAM$RVALID   (emu_ram_rvalid),
        .\$EMU$RAM$WDATA    (emu_ram_wdata),
        .\$EMU$RAM$WDONE    (emu_ram_wdone),
        .\$EMU$RAM$WID      (emu_ram_wid),
        .\$EMU$RAM$WREADY   (emu_ram_wready),
        .\$EMU$RAM$WREQ     (emu_ram_wreq),
        .\$EMU$RAM$WVALID   (emu_ram_wvalid)
    );

    sim_ram #(.WIDTH(32), .DEPTH(1024)) u_ram (
        .clk(clk),
        .wen1(MemWrite),
        .waddr1(Address[11:2]),
        .wdata1(Write_data),
        .wstrb1(Write_strb),
        .wen2(1'b0),
        .waddr2(10'd0),
        .wdata2(32'd0),
        .wstrb2(4'd0),
        .raddr1(PC[11:2]),
        .rdata1(Instruction),
        .raddr2(Address[11:2]),
        .rdata2(Read_data)
    );

    always @(posedge clk) begin
        if (MemWrite && Address == 32'hc) begin
            $display("[%dns] simulation finished with result = %d", $time, Write_data);
            $finish;
        end
    end

    reg [63:0] ram_data [15:0];
    integer i;

    initial begin
        clk = 0;
        rst = 1;
        emu_halt = 0;
        emu_ram_rreq = 0;
        emu_ram_wreq = 0;
        emu_ram_rready = 0;
        emu_ram_wvalid = 0;
        emu_raddr = 0;
        emu_waddr = 0;
        emu_ram_rid = 0;
        emu_ram_wid = 0;
        emu_wen = 0;
        emu_wdata = 0;
        emu_ram_wdata = 0;
        #50;
        rst = 0;
        #1000;
        @(posedge clk); #5;
        emu_halt = 1;
        #50;
        // do_ram_read();
        i = 0;
        @(posedge clk); #5;
        emu_ram_rid = 0;
        emu_ram_rreq = 1;
        @(posedge clk); #5;
        emu_ram_rreq = 0;
        emu_ram_rready = 1;
        @(posedge clk);
        while (!emu_ram_rdone) begin
            while (!emu_ram_rvalid) @(posedge clk);
            ram_data[i] = emu_ram_rdata;
            i = i + 1;
            @(posedge clk);
        end
        #5;
        emu_ram_rready = 0;
        // do_ram_write();
        i = 0;
        @(posedge clk); #5;
        emu_ram_wid = 0;
        emu_ram_wreq = 1;
        @(posedge clk); #5;
        emu_ram_wreq = 0;
        emu_ram_wvalid = 1;
        while (!emu_ram_wdone) begin
            emu_ram_wdata = ram_data[i];
            i = i + 1;
            @(posedge clk);
            while (!emu_ram_wready && !emu_ram_wdone) @(posedge clk);
            #5;
        end
        emu_ram_wvalid = 0;
        #50;
        @(posedge clk); #5;
        emu_halt = 0;
    end

    initial begin
        $dumpfile("output/dump.vcd");
        $dumpvars();
    end

endmodule
