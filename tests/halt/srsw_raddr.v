module srsw_raddr(
    input clk,
    input wen,
    input [1:0] waddr,
    input [31:0] wdata,
    input ren,
    input [1:0] raddr,
    output [31:0] rdata
);

    reg [31:0] mem [3:0];
    reg [1:0] raddr_reg;

    always @(posedge clk) begin
        if (wen) mem[waddr] <= wdata;
    end

    always @(posedge clk) begin
        raddr_reg <= raddr;
    end

    assign rdata = mem[raddr_reg];

endmodule
