`timescale 1 ns / 1 ps

module ff(
    input [63:0] d1,
    input [31:0] d2,
    input [7:0] d3,
    input [79:0] d4,
    output reg [63:0] q1,
    output reg [31:0] q2,
    output reg [7:0] q3,
    output reg [79:0] q4
);

    wire clk, rst;
    EmuClock clock(.clock(clk));
    EmuReset reset(.reset(rst));

    always @(posedge clk) begin
        if (rst) begin
            q1 <= 64'd0;
            q2 <= 32'd0;
            q3 <= 8'd0;
            q4 <= 80'd0;
        end
        else begin
            q1 <= d1;
            q2 <= d2;
            q3 <= d3;
            q4 <= d4;
        end
    end

endmodule
