`timescale 1 ns / 1 ps

module chain(
    input                   ren1,
    input   [2:0]           raddr1,
    output  [31:0]          rdata1,
    input                   wen1,
    input   [2:0]           waddr1,
    input   [31:0]          wdata1,
    input                   ren2,
    input   [2:0]           raddr2,
    output  [63:0]          rdata2,
    input                   wen2,
    input   [2:0]           waddr2,
    input   [63:0]          wdata2,
    input                   ren3,
    input   [2:0]           raddr3,
    output  [127:0]          rdata3,
    input                   wen3,
    input   [2:0]           waddr3,
    input   [127:0]          wdata3
);

    wire clk, rst;
    EmuClock clock(clk);
    EmuReset reset(clk, rst);

    mem #(
        .WIDTH(32),
        .DEPTH(8),
        .OFFSET(0),
        .SYNCREAD(1)
    )
    u_mem1 (
        .clk(clk),
        .rst(rst),
        .ren(ren1),
        .raddr(raddr1),
        .rdata(rdata1),
        .wen(wen1),
        .waddr(waddr1),
        .wdata(wdata1)
    );

    mem #(
        .WIDTH(64),
        .DEPTH(8),
        .OFFSET(0),
        .SYNCREAD(1)
    )
    u_mem2 (
        .clk(clk),
        .rst(rst),
        .ren(ren2),
        .raddr(raddr2),
        .rdata(rdata2),
        .wen(wen2),
        .waddr(waddr2),
        .wdata(wdata2)
    );

    mem #(
        .WIDTH(128),
        .DEPTH(8),
        .OFFSET(0),
        .SYNCREAD(1)
    )
    u_mem3 (
        .clk(clk),
        .rst(rst),
        .ren(ren3),
        .raddr(raddr3),
        .rdata(rdata3),
        .wen(wen3),
        .waddr(waddr3),
        .wdata(wdata3)
    );

endmodule
