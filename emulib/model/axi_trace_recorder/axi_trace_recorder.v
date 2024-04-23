`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module axi4_trace_recorder #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   CHANNEL_SEQ     = 0
) (
    input clk,
    input rst,
    `AXI4_SLAVE_IF                  (s_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF                 (m_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    output wire                     o_valid,
    input  wire                     o_ready,
    output wire [512/8-1:0]         o_keep,
    output wire [512-1:0]           o_data,
    output wire                     o_last
);
    // formanted payload length + timestamp width
    localparam A_PAYLOAD_FORMANTTED_WIDTH = (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/64*64+64+64;
    localparam R_PAYLOAD_FORMANTTED_WIDTH = (`AXI4_CUSTOM_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/64*64+64+64;
    localparam W_PAYLOAD_FORMANTTED_WIDTH = (`AXI4_CUSTOM_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/64*64+64+64;
    localparam B_PAYLOAD_FORMANTTED_WIDTH = (`AXI4_CUSTOM_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))/64*64+64+64;
    
    wire logging_arvalid;
    wire logging_arready;
    wire [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_ar_payload;
    wire logging_awvalid;
    wire logging_awready;
    wire [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_aw_payload;
    wire logging_rvalid;
    wire logging_rready;
    wire [R_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_r_payload;
    wire logging_wvalid;
    wire logging_wready;
    wire [W_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_w_payload;
    wire logging_bvalid;
    wire logging_bready;
    wire [B_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_b_payload;

    axi_trace_encoder #(
        .A_PAYLOAD_FORMANTTED_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH),
        .R_PAYLOAD_FORMANTTED_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH),
        .W_PAYLOAD_FORMANTTED_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH),
        .B_PAYLOAD_FORMANTTED_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH),
        .CHANNEL_SEQ(CHANNEL_SEQ)
    )axi4_trace_encoder (
        .logging_arvalid(logging_arvalid),
        .logging_arready(logging_arready),
        .logging_ar_payload(logging_ar_payload),
        .logging_awvalid(logging_awvalid),
        .logging_awready(logging_awready),
        .logging_aw_payload(logging_aw_payload),
        .logging_rvalid(logging_rvalid),
        .logging_rready(logging_rready),
        .logging_r_payload(logging_r_payload),
        .logging_wvalid(logging_wvalid),
        .logging_wready(logging_wready),
        .logging_w_payload(logging_w_payload),
        .logging_bvalid(logging_bvalid),
        .logging_bready(logging_bready),
        .logging_b_payload(logging_b_payload),
        .o_valid(o_valid),
        .o_ready(o_ready),
        .o_keep(o_keep),
        .o_data(o_data),
        .o_last(o_last)
    );

    axi4_channel_logger #(
        .A_PAYLOAD_FORMANTTED_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH),
        .R_PAYLOAD_FORMANTTED_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH),
        .W_PAYLOAD_FORMANTTED_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH),
        .B_PAYLOAD_FORMANTTED_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    )axi4_channel_logger (
        .logging_arvalid(logging_arvalid),
        .logging_arready(logging_arready),
        .logging_ar_payload(logging_ar_payload),
        .logging_awvalid(logging_awvalid),
        .logging_awready(logging_awready),
        .logging_aw_payload(logging_aw_payload),
        .logging_rvalid(logging_rvalid),
        .logging_rready(logging_rready),
        .logging_r_payload(logging_r_payload),
        .logging_wvalid(logging_wvalid),
        .logging_wready(logging_wready),
        .logging_w_payload(logging_w_payload),
        .logging_bvalid(logging_bvalid),
        .logging_bready(logging_bready),
        .logging_b_payload(logging_b_payload),
        `AXI4_CONNECT           (s_axi, s_axi),
        `AXI4_CONNECT           (m_axi, m_axi)
    );
endmodule