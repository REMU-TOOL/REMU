`timescale 1ns / 1ps

`include "axi.vh"

module rammodel_test #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h1
)(
    input                       host_clk,
    input                       host_rst,

    output                      target_clk,
    input                       target_rst,

    `AXI4_SLAVE_IF              (s_axi,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (host_axi,  ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (lsu_axi, 32, 32, 1),

    input                       pause,

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down
);

    wire stall;
    wire target_fire = !pause && !stall;

    reg en_latch;
    always @(host_clk or target_fire)
        if (~host_clk)
            en_latch = target_fire;
    assign target_clk = host_clk & en_latch;

    integer target_cnt = 0;
    always @(posedge target_clk) target_cnt <= target_cnt + 1;

    EmuRam #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .PF_COUNT   (PF_COUNT)
    )
    uut (
        .clk            (target_clk),
        .rst            (target_rst),
        `AXI4_CONNECT   (s_axi, s_axi),
        .host_clk       (host_clk),
        .host_rst       (host_rst),
        `AXI4_CONNECT   (host_axi, host_axi),
        `AXI4_CONNECT_NO_ID (lsu_axi, lsu_axi),
        .target_fire    (target_fire),
        .stall          (stall),
        .up_req         (up_req),
        .down_req       (down_req),
        .up_stat        (up),
        .down_stat      (down)
    );

    assign lsu_axi_arid = 0;
    assign lsu_axi_awid = 0;

endmodule
