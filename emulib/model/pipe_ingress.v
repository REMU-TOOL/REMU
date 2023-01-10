`timescale 1ns / 1ps

module EmuIngressPipe #(
    parameter DATA_WIDTH = 1
)(
    input  wire                     clk,
    input  wire                     enable,
    output wire                     valid,
    output wire [DATA_WIDTH-1:0]    data
);

    wire [DATA_WIDTH-1:0] raw_data;

    emulib_ingress_pipe_imp #(
        .DATA_WIDTH (DATA_WIDTH)
    ) imp (
        .clk    (clk),
        .enable (enable),
        .valid  (valid),
        .data   (raw_data)
    );

    assign data = valid ? raw_data : {DATA_WIDTH{1'b0}};

endmodule
