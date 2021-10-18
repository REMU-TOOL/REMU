`timescale 1 ns / 1 ps

module offset(
    input   [5:0]           raddr,
    output  [79:0]          rdata,
    input                   wen,
    input   [5:0]           waddr,
    input   [79:0]          wdata
);

    wire clk, rst;
    EmuClock clock(clk);
    EmuReset reset(rst);

    mem #(
        .WIDTH(80),
        .DEPTH(32),
        .OFFSET(32),
        .SYNCREAD(0)
    )
    u_mem (
        .clk(clk),
        .rst(rst),
        .ren(1'b0),
        .raddr(raddr),
        .rdata(rdata),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata)
    );

endmodule
