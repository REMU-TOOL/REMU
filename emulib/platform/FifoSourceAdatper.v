`timescale 1ns / 1ps

module FifoSourceAdatper #(
    parameter DATA_WIDTH = 1,
    parameter __DATA_REG_CNT = (DATA_WIDTH + 31) / 32
)(

    input                           clk,
    input                           rst,

    input       [__DATA_REG_CNT:0]  reg_wen,
    input       [31:0]              reg_wdata,
    input       [__DATA_REG_CNT:0]  reg_ren,
    output reg  [31:0]              reg_rdata,

    output                          fifo_wen,
    output reg  [DATA_WIDTH-1:0]    fifo_wdata,
    input                           fifo_wfull

);

    // Register space:
    //   0: STAT [RO] CTRL [WO]
    //   1: DATA_1 [RW]
    //   2: DATA_2 [RW]
    //   ...
    //   N: DATA_N [RW]

    // STAT: [0] = full
    // CTRL: do fifo write when written

    integer i;

    always @(posedge clk) begin
        for (i=0; i<__DATA_REG_CNT; i=i+1) begin
            if (reg_wen[i+1]) begin
                fifo_wdata[32*i+:32] <= reg_wdata;
            end
        end
    end

    always @* begin
        reg_rdata = {32{reg_ren[0]}} & {31'd0, fifo_wfull};
        for (i=0; i<__DATA_REG_CNT; i=i+1) begin
            reg_rdata = reg_rdata | {32{reg_ren[i+1]}} & fifo_wdata[32*i+:32];
        end
    end

    assign fifo_wen = reg_wen[0];

endmodule
