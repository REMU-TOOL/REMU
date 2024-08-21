`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module axilite_trace_recorder #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   AXI_MODE        = 0
) (
    input clk,
    input rst,
    `AXI4LITE_SLAVE_IF                  (s_axi, ADDR_WIDTH, DATA_WIDTH),
    `AXI4LITE_MASTER_IF                 (m_axi, ADDR_WIDTH, DATA_WIDTH)
);
    /*
     * Cycle == 64 BIT
     * Channel Num == 3 BIT
     * Event Sel == 5 BIT
     * AR AW R W B -- 8 BIT aligned
     */
    // formanted payload length + timestamp width
    localparam PROT_WIDTH = 3;
    localparam RESP_WIDTH = 2;
    localparam A_PAYLOAD_FORMANTTED_WIDTH = ADDR_WIDTH + PROT_WIDTH;
    localparam R_PAYLOAD_FORMANTTED_WIDTH = DATA_WIDTH + RESP_WIDTH;
    localparam W_PAYLOAD_FORMANTTED_WIDTH = DATA_WIDTH + DATA_WIDTH/8;
    localparam B_PAYLOAD_FORMANTTED_WIDTH = RESP_WIDTH;
    
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
    
    EmuTracePort #(.DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH)) AR_Channel (
        .clk(clk),
        .data(logging_ar_payload),
        .enable(logging_arvalid)
    );

    EmuTracePort #(.DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH)) AW_Channel (
        .clk(clk),
        .data(logging_aw_payload),
        .enable(logging_awvalid)
    );

    EmuTracePort #(.DATA_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH)) R_Channel (
        .clk(clk),
        .data(logging_r_payload),
        .enable(logging_rvalid)
    );


    EmuTracePort #(.DATA_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH)) W_Channel (
        .clk(clk),
        .data(logging_w_payload),
        .enable(logging_wvalid)
    );

    EmuTracePort #(.DATA_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH)) B_Channel (
        .clk(clk),
        .data(logging_b_payload),
        .enable(logging_bvalid)
    );

    axilite_channel_logger #(
        .A_PAYLOAD_FORMANTTED_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH),
        .R_PAYLOAD_FORMANTTED_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH),
        .W_PAYLOAD_FORMANTTED_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH),
        .B_PAYLOAD_FORMANTTED_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    )axilite_channel_logger (
        .clk(clk),
        .rst(rst),
        .logging_arvalid(logging_arvalid),
        .logging_arready(1),
        .logging_ar_payload(logging_ar_payload),
        .logging_awvalid(logging_awvalid),
        .logging_awready(1),
        .logging_aw_payload(logging_aw_payload),
        .logging_rvalid(logging_rvalid),
        .logging_rready(1),
        .logging_r_payload(logging_r_payload),
        .logging_wvalid(logging_wvalid),
        .logging_wready(1),
        .logging_w_payload(logging_w_payload),
        .logging_bvalid(logging_bvalid),
        .logging_bready(1),
        .logging_b_payload(logging_b_payload),
        `AXI4LITE_CONNECT           (s_axi, s_axi),
        `AXI4LITE_CONNECT           (m_axi, m_axi)
    );
endmodule
