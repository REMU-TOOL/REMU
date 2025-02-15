`timescale 1 ns / 1 ps

module srsw2(
    (* remu_clock *)
    input clk,
    input   [2:0]           raddr,
    output  [79:0]          rdata,
    input                   wen,
    input   [2:0]           waddr,
    input   [79:0]          wdata
);

    reg [79:0] mem [7:0];
    reg [2:0] raddr_reg;

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    always @(posedge clk) begin
        raddr_reg <= raddr;
    end

    assign rdata = mem[raddr_reg];

endmodule
