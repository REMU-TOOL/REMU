`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module axi4_channel_logger #(
    parameter   A_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   R_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   W_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   B_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(
    input clk,
    input rst,
    `AXI4_SLAVE_IF                  (s_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF                 (m_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    //RECORD INTERFACE
    output logging_arvalid,
    input  logging_arready,
    output [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_ar_payload,
    output logging_awvalid,
    input  logging_awready,
    output [A_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_aw_payload,
    output logging_wvalid,
    input  logging_wready,
    output [W_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_w_payload,
    output logging_bvalid,
    input  logging_bready,
    output [B_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_b_payload,
    output logging_rvalid,
    input  logging_rready,
    output [R_PAYLOAD_FORMANTTED_WIDTH-1:0] logging_r_payload
);
    localparam AR_LOG_EVENT = 4'd1;
    localparam AW_LOG_EVENT = 4'd2;
    localparam R_LOG_EVENT = 4'd3;
    localparam W_LOG_EVENT = 4'd4;
    localparam B_LOG_EVENT = 4'd5;

    reg [63:0] target_cycles, ar_log_cycle, aw_log_cycle, r_log_cycle, w_log_cycle, b_log_cycle;

    always @(posedge clk ) begin
        if(rst)
            target_cycles <= 0;
        else
            target_cycles <= target_cycles + 1;
    end

    always @(posedge clk ) begin
        if(rst) 
            ar_log_cycle <= 0;
        else if(logging_arvalid && logging_arready)
            ar_log_cycle <= target_cycles + 1;
    end

    always @(posedge clk ) begin
        if(rst) 
            aw_log_cycle <= 0;
        else if(logging_awvalid && logging_awready)
            aw_log_cycle <= target_cycles + 1;
    end

    always @(posedge clk ) begin
        if(rst) 
            r_log_cycle <= 0;
        else if(logging_rvalid && logging_rready)
            r_log_cycle <= target_cycles + 1;
    end

    always @(posedge clk ) begin
        if(rst) 
            w_log_cycle <= 0;
        else if(logging_wvalid && logging_wready)
            w_log_cycle <= target_cycles + 1;
    end

    always @(posedge clk ) begin
        if(rst) 
            b_log_cycle <= 0;
        else if(logging_bvalid && logging_bready)
            b_log_cycle <= target_cycles + 1;
    end

    twoway_valid_ready_logger ar_logger #(
        .DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH),
        .LOG_EVENT(AR_LOG_EVENT))
    (
        .clk(clk),
        .rst(rst),
        .in_valid(s_axi_arvalid),
        .in_ready(s_axi_arready),
        .in_data(`AXI4_AR_PAYLOAD(s_axi)),
        .out_valid(m_axi_arvalid),
        .out_ready(m_axi_arready),
        .out_data(`AXI4_AR_PAYLOAD(m_axi)),
        .log_valid(logging_arvalid),
        .log_ready(logging_arready),
        .log_data(logging_ar_payload[A_PAYLOAD_FORMANTTED_WIDTH-1:64])
    );
    assign logging_ar_payload[63:0] = ar_log_cycle;

        twoway_valid_ready_logger aw_logger #(
        .DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH),
        .LOG_EVENT(AW_LOG_EVENT))
    (
        .clk(clk),
        .rst(rst),
        .in_valid(s_axi_awvalid),
        .in_ready(s_axi_awready),
        .in_data(`AXI4_AW_PAYLOAD(s_axi)),
        .out_valid(m_axi_awvalid),
        .out_ready(m_axi_awready),
        .out_data(`AXI4_AW_PAYLOAD(m_axi)),
        .log_valid(logging_awvalid),
        .log_ready(logging_awready),
        .log_data(logging_aw_payload[A_PAYLOAD_FORMANTTED_WIDTH-1:64])
    );
    assign logging_aw_payload[63:0] = aw_log_cycle;

    twoway_valid_ready_logger w_logger #(
        .DATA_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH),
        .LOG_EVENT(W_LOG_EVENT))
    (
        .clk(clk),
        .rst(rst),
        .in_valid(s_axi_wvalid),
        .in_ready(s_axi_wready),
        .in_data(`AXI4_W_PAYLOAD(s_axi)),
        .out_valid(m_axi_wvalid),
        .out_ready(m_axi_wready),
        .out_data(`AXI4_W_PAYLOAD(m_axi)),
        .log_valid(logging_wvalid),
        .log_ready(logging_wready),
        .log_data(logging_w_payload[W_PAYLOAD_FORMANTTED_WIDTH-1:64])
    );
    assign logging_w_payload[63:0] = w_log_cycle;

    twoway_valid_ready_logger r_logger #(
        .DATA_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH),
        .LOG_EVENT(R_LOG_EVENT))
    (
        .clk(clk),
        .rst(rst),
        .in_valid(m_axi_rvalid),
        .in_ready(m_axi_rready),
        .in_data(`AXI4_R_PAYLOAD(m_axi)),
        .out_valid(s_axi_rvalid),
        .out_ready(s_axi_rready),
        .out_data(`AXI4_R_PAYLOAD(s_axi)),
        .log_valid(logging_rvalid),
        .log_ready(logging_rready),
        .log_data(logging_r_payload[R_PAYLOAD_FORMANTTED_WIDTH-1:64])
    );
    assign logging_r_payload[63:0] = r_log_cycle;

    twoway_valid_ready_logger b_logger #(
        .DATA_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH),
        .LOG_EVENT(B_LOG_EVENT))
    (
        .clk(clk),
        .rst(rst),
        .in_valid(m_axi_bvalid),
        .in_ready(m_axi_bready),
        .in_data(`AXI4_B_PAYLOAD(m_axi)),
        .out_valid(s_axi_bvalid),
        .out_ready(s_axi_bready),
        .out_data(`AXI4_B_PAYLOAD(s_axi)),
        .log_valid(logging_bvalid),
        .log_ready(logging_bready),
        .log_data(logging_b_payload[B_PAYLOAD_FORMANTTED_WIDTH-1:64])
    );
    assign logging_b_payload[63:0] = b_log_cycle;


endmodule