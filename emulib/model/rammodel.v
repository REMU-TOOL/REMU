`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_custom.vh"

(* keep, __emu_directive = {
    "extern host_clk;",
    "extern host_rst;",
    "extern -axi host_axi;",
    "extern -axi lsu_axi;",
    "extern target_fire;",
    "extern stall;",
    "extern up_req;",
    "extern down_req;",
    "extern up_stat;",
    "extern down_stat;"
} *)

module EmuRam #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h10000,
    parameter   MAX_INFLIGHT    = 8,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input  wire                 clk,
    input  wire                 rst,

    `AXI4_SLAVE_IF              (s_axi,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input  wire                 host_clk,
    input  wire                 host_rst,

    `AXI4_MASTER_IF             (host_axi,      ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF_NO_ID       (lsu_axi, 32, 32),

    input  wire                 target_fire,
    output wire                 stall,

    input  wire                 up_req,
    input  wire                 down_req,
    output wire                 up_stat,
    output wire                 down_stat

);

    `AXI4_CUSTOM_A_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    wire                 rreq_valid;
    wire [ID_WIDTH-1:0]  rreq_id;

    wire                 breq_valid;
    wire [ID_WIDTH-1:0]  breq_id;

    emulib_rammodel_frontend #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .MAX_INFLIGHT   (MAX_INFLIGHT),
        .R_DELAY        (R_DELAY),
        .W_DELAY        (W_DELAY)
    )
    frontend (

        .target_clk             (clk),
        .target_rst             (rst),

        `AXI4_CONNECT           (target_axi, s_axi),

        `AXI4_CUSTOM_A_CONNECT  (backend, f2b),
        `AXI4_CUSTOM_W_CONNECT  (backend, f2b),
        `AXI4_CUSTOM_B_CONNECT  (backend, f2b),
        `AXI4_CUSTOM_R_CONNECT  (backend, f2b),

        .rreq_valid             (rreq_valid),
        .rreq_id                (rreq_id),

        .breq_valid             (breq_valid),
        .breq_id                (breq_id)

    );

    emulib_rammodel_backend #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .PF_COUNT       (PF_COUNT),
        .MAX_INFLIGHT   (MAX_INFLIGHT)
    )
    backend (

        .host_clk               (host_clk),
        .host_rst               (host_rst),

        .target_clk             (clk),
        .target_rst             (rst),

        `AXI4_CUSTOM_A_CONNECT  (frontend, f2b),
        `AXI4_CUSTOM_W_CONNECT  (frontend, f2b),
        `AXI4_CUSTOM_B_CONNECT  (frontend, f2b),
        `AXI4_CUSTOM_R_CONNECT  (frontend, f2b),

        .rreq_valid             (rreq_valid),
        .rreq_id                (rreq_id),

        .breq_valid             (breq_valid),
        .breq_id                (breq_id),

        `AXI4_CONNECT           (host_axi, host_axi),
        `AXI4_CONNECT_NO_ID     (lsu_axi, lsu_axi),

        .target_fire            (target_fire),
        .stall                  (stall),

        .up_req                 (up_req),
        .down_req               (down_req),
        .up_stat                (up_stat),
        .down_stat              (down_stat)

    );

endmodule

`default_nettype wire
