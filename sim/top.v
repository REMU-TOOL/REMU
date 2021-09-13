`timescale 1 ns / 1 ns

`define CHECKPOINT_PATH "checkpoint"
`define DUT_INST u_cpu

`include "loader.vh"

module sim_top();

    parameter CYCLE = 10;

    reg clk = 1, __clk_en = 0;
    always #(CYCLE/2) clk = ~clk;

    wire [31:0] PC;
    wire [31:0] Instruction;
    wire [31:0] Address;
    wire MemWrite;
    wire [31:0] Write_data;
    wire [3:0] Write_strb;
    wire MemRead;
    wire [31:0] Read_data;

    mips_cpu u_cpu ( 
        .clk                (clk & __clk_en),
        .rst                (0),
        .PC                 (PC),
        .Instruction        (Instruction),
        .Address            (Address),
        .MemWrite           (MemWrite),
        .Write_data         (Write_data),
        .Write_strb         (Write_strb),
        .MemRead            (MemRead),
        .Read_data          (Read_data)
    );

    ideal_mem #(.WIDTH(32), .DEPTH(1024)) u_mem (
        .clk                (clk),
        .wen1               (MemWrite),
        .waddr1             (Address[11:2]),
        .wdata1             (Write_data),
        .wstrb1             (Write_strb),
        .raddr1             (PC[11:2]),
        .rdata1             (Instruction),
        .raddr2             (Address[11:2]),
        .rdata2             (Read_data)
    );

    

    reg [63:0] __start_cycle, __run_cycle, __cycle;
    `LOADER_DEFS

    initial begin
        if (!$value$plusargs("startcycle=%d", __start_cycle)) begin
            $display("ERROR: startcycle not specified");
            $finish;
        end
        if (!$value$plusargs("runcycle=%d", __run_cycle)) begin
            $display("ERROR: startcycle not specified");
            $finish;
        end
        $dumpfile("output/reconstruct.vcd");
        $dumpvars();
        __cycle = 0;
    end

    always @(posedge clk) begin
        __cycle = __cycle + 1;
        if (__cycle == __start_cycle) begin
            $display("[%dns] Loading checkpoint ...", $time);
            `LOADER_STMTS
            $readmemh({`CHECKPOINT_PATH, "/idealmem.txt"}, u_mem.mem);
        end
        else if (__cycle == __start_cycle + 1) begin
            __clk_en = 1;
        end
        else if (__cycle == __start_cycle + __run_cycle) begin
            $finish;
        end
    end

endmodule

module ideal_mem #(
    parameter WIDTH = 32,
    parameter DEPTH = 1024,
    parameter AWIDTH = $clog2(DEPTH)
)(
    input clk,
    input wen1,
    input [AWIDTH-1:0] waddr1,
    input [WIDTH-1:0] wdata1,
    input [WIDTH/8-1:0] wstrb1,
    input [AWIDTH-1:0] raddr1,
    output [WIDTH-1:0] rdata1,
    input [AWIDTH-1:0] raddr2,
    output [WIDTH-1:0] rdata2
);

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    integer i;
    always @(posedge clk) begin
        for (i=0; i<WIDTH/8; i=i+1) if (wen1 && wstrb1[i]) mem[waddr1][i*8+:8] <= wdata1[i*8+:8];
    end

    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];

endmodule
