`timescale 1 ns / 1 ps

module ffpause(
    input en,
    input [31:0] d,
    output reg [31:0] q
);

    wire clk, rst;
    EmuClock clock(.clock(clk));
    EmuReset reset(.reset(rst));

    always @(posedge clk) begin
        if (rst) q <= 32'd0;
        else if (en) q <= d;
    end

endmodule
