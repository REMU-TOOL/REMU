`timescale 1ns / 1ps

module FifoSinkAdapter #(
    parameter DATA_WIDTH = 1,
    parameter __DATA_REG_CNT = (DATA_WIDTH + 31) / 32
)(

    input                           clk,
    input                           rst,

    input       [__DATA_REG_CNT:0]  reg_wen,
    input       [31:0]              reg_wdata,
    input       [__DATA_REG_CNT:0]  reg_ren,
    output reg  [31:0]              reg_rdata,

    output                          fifo_ren,
    input       [DATA_WIDTH-1:0]    fifo_rdata,
    input                           fifo_rempty

);

    // Register space:
    //   0: STAT [RO] CTRL [WO]
    //   1: DATA_1 [RO]
    //   2: DATA_2 [RO]
    //   ...
    //   N: DATA_N [RO]

    // STAT: [0] = empty
    // CTRL: do fifo read when written

    integer i;

    always @* begin
        reg_rdata = {32{reg_ren[0]}} & {31'd0, fifo_rempty};
        for (i=0; i<__DATA_REG_CNT; i=i+1) begin
            reg_rdata = reg_rdata | {32{reg_ren[i+1]}} & fifo_rdata[32*i+:32];
        end
    end

    assign fifo_ren = reg_wen[0];

endmodule
