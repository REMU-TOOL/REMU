`timescale 1 ns / 1 ps

module emu_top();

    wire clk, rst, trig;
    EmuClock clock(clk);
    EmuReset reset(clk, rst);
    EmuTrigger trigger(trig);

    wire [31:0] PC;
    wire [31:0] Instruction;
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

    assign trig = MemWrite && Address == 32'hc;

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
