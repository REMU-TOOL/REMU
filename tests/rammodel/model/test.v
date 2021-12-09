`timescale 1ns / 1ps

`include "axi.vh"

module rammodel_test #(
    parameter   ADDR_WIDTH              = 32,
    parameter   DATA_WIDTH              = 64,
    parameter   ID_WIDTH                = 4
)(
    input                       clk,
    input                       resetn,

    `AXI4_SLAVE_IF              (s_dut,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (m_dram,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input                       pause,

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down,

    output                      dut_stall,

    // for testbench use
    output                      dut_clk
);

    rammodel_simple #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    )
    uut (
        .clk            (clk),
        .resetn         (resetn),
        `AXI4_CONNECT   (s_dut, s_dut),
        `AXI4_CONNECT   (m_dram, m_dram),
        .pause          (pause),
        .up_req         (up_req),
        .down_req       (down_req),
        .up             (up),
        .down           (down),
        .dut_stall      (dut_stall)
    );

    wire dut_clk_en = !dut_stall;

    reg en_latch;
    always @(clk or dut_clk_en)
        if (~clk)
            en_latch = dut_clk_en;
    assign dut_clk = clk & en_latch;

    integer dut_cnt = 0;
    always @(posedge dut_clk) dut_cnt = dut_cnt + 1;

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile(`DUMPFILE);
            $dumpvars();
        end
    end

endmodule
