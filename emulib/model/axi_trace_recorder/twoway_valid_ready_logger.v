`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module twoway_valid_ready_logger #(
    parameter DATA_WIDTH = 64,
    parameter LOG_EVENT = 0
)(
    input  clk,
    input  rst,
    input  in_valid,
    output in_ready,
    input  [DATA_WIDTH-1:0]in_data,
    output out_valid,
    input  out_ready,
    output [DATA_WIDTH-1:0] out_data,
    output log_valid,
    input  log_ready,
    output [DATA_WIDTH-1:0] log_data
);

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_log(
        .i_valid        (in_valid),
        .i_ready        (in_ready),
        .o_valid        ({log_valid, out_valid}),
        .o_ready        ({log_ready, out_ready})
    );

    assign out_data = in_data;
    assign log_data = in_data;
    
endmodule