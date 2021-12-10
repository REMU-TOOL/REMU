`timescale 1 ns / 1 ps

module srsw_rdata(
    input wen,
    input [1:0] waddr,
    input [31:0] wdata,
    input ren,
    input [1:0] raddr,
    output [31:0] rdata
);

    wire clk, rst;
    EmuClock clock(clk);
    EmuReset reset(rst);

    reg [31:0] mem [3:0], o;

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    always @(posedge clk) begin
        if (rst) o <= 32'd0;
        else if (ren) o <= mem[raddr];
    end

    assign rdata = o;

endmodule
