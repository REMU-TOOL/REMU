module srsw(
    input                   clk,
    input                   rst,
    input                   ren,
    input   [2:0]           raddr,
    output  [79:0]          rdata,
    input                   wen,
    input   [2:0]           waddr,
    input   [79:0]          wdata
);

    mem #(
        .WIDTH(80),
        .DEPTH(8),
        .OFFSET(0),
        .SYNCREAD(1)
    )
    u_mem (
        .clk(clk),
        .rst(rst),
        .ren(ren),
        .raddr(raddr),
        .rdata(rdata),
        .wen(wen),
        .waddr(waddr),
        .wdata(wdata)
    );

endmodule
