`timescale 1 ns / 1 ps

module mem #(
    parameter WIDTH = 32,
    parameter DEPTH = 32,
    parameter OFFSET = 0,
    parameter SYNCREAD = 1,
    parameter AWIDTH = $clog2(OFFSET+DEPTH)
)(
    input                   clk,
    input                   rst,
    input                   ren,
    input   [AWIDTH-1:0]    raddr,
    output  [WIDTH-1:0]     rdata,
    input                   wen,
    input   [AWIDTH-1:0]    waddr,
    input   [WIDTH-1:0]     wdata
);

    reg [WIDTH-1:0] mem [OFFSET:OFFSET+DEPTH-1];

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    if (SYNCREAD) begin
        reg [WIDTH-1:0] o;

        always @(posedge clk) begin
            if (rst) o <= 0;
            else if (ren) o <= mem[raddr];
        end

        assign rdata = o;
    end
    else begin
        assign rdata = mem[raddr];
    end

endmodule
