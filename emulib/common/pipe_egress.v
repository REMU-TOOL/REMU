`timescale 1ns / 1ps

module EmuEgressPipe #(
    parameter DATA_WIDTH = 1
)(
    input  wire                     clk,
    input  wire                     valid,
    input  wire [DATA_WIDTH-1:0]    data
);

    emulib_egress_pipe_imp #(
        .DATA_WIDTH (DATA_WIDTH)
    ) imp (
        .clk    (clk),
        .valid  (valid),
        .data   (data)
    );

endmodule
