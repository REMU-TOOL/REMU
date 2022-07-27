`timescale 1 ns / 1 ps

module emu_top();

    wire clk, rst;
    EmuClock clock(.clock(clk));
    EmuReset reset(.reset(rst));

    reg [63:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count <= 64'd0;
        end
        else begin
            count <= count + 1;
        end
    end

    EmuDataSink #(
        .DATA_WIDTH(64)
    ) u_trace (
        .clk    (clk),
        .wen    (!rst),
        .wdata  (count)
    );

endmodule
