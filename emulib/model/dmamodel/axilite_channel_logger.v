`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module axilite_channel_logger #(
    parameter   A_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   R_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   W_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   B_PAYLOAD_FORMANTTED_WIDTH      = 64,
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64
)(
    input clk,
    input rst,
    `AXI4LITE_SLAVE_IF                  (s_axi, ADDR_WIDTH, DATA_WIDTH),
    `AXI4LITE_MASTER_IF                 (m_axi, ADDR_WIDTH, DATA_WIDTH),
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

    twoway_valid_ready_logger #(
        .DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH)
    )ar_logger(
        .clk(clk),
        .rst(rst),
        .in_valid(s_axi_arvalid),
        .in_ready(s_axi_arready),
        .in_data({s_axi_arprot,s_axi_araddr}),
        .out_valid(m_axi_arvalid),
        .out_ready(m_axi_arready),
        .out_data({m_axi_arprot,m_axi_araddr}),
        .log_valid(logging_arvalid),
        .log_ready(logging_arready),
        .log_data(logging_ar_payload)
    );

    twoway_valid_ready_logger  #(
        .DATA_WIDTH(A_PAYLOAD_FORMANTTED_WIDTH))
    aw_logger(
        .clk(clk),
        .rst(rst),
        .in_valid(s_axi_awvalid),
        .in_ready(s_axi_awready),
        .in_data({s_axi_awprot,s_axi_awaddr}),
        .out_valid(m_axi_awvalid),
        .out_ready(m_axi_awready),
        .out_data({m_axi_awprot,m_axi_awaddr}),
        .log_valid(logging_awvalid),
        .log_ready(logging_awready),
        .log_data(logging_aw_payload)
    );

    twoway_valid_ready_logger  #(
        .DATA_WIDTH(W_PAYLOAD_FORMANTTED_WIDTH))
    w_logger(
        .clk(clk),
        .rst(rst),
        .in_valid(s_axi_wvalid),
        .in_ready(s_axi_wready),
        .in_data({s_axi_wstrb,s_axi_wdata}),
        .out_valid(m_axi_wvalid),
        .out_ready(m_axi_wready),
        .out_data({m_axi_wstrb,m_axi_wdata}),
        .log_valid(logging_wvalid),
        .log_ready(logging_wready),
        .log_data(logging_w_payload)
    );

    twoway_valid_ready_logger  #(
        .DATA_WIDTH(R_PAYLOAD_FORMANTTED_WIDTH))
    r_logger(
        .clk(clk),
        .rst(rst),
        .in_valid(m_axi_rvalid),
        .in_ready(m_axi_rready),
        .in_data({s_axi_rresp,s_axi_rdata}),
        .out_valid(s_axi_rvalid),
        .out_ready(s_axi_rready),
        .out_data({m_axi_rresp,m_axi_rdata}),
        .log_valid(logging_rvalid),
        .log_ready(logging_rready),
        .log_data(logging_r_payload)
    );

    twoway_valid_ready_logger  #(
        .DATA_WIDTH(B_PAYLOAD_FORMANTTED_WIDTH))
    b_logger(
        .clk(clk),
        .rst(rst),
        .in_valid(m_axi_bvalid),
        .in_ready(m_axi_bready),
        .in_data({s_axi_bresp}),
        .out_valid(s_axi_bvalid),
        .out_ready(s_axi_bready),
        .out_data({m_axi_bresp}),
        .log_valid(logging_bvalid),
        .log_ready(logging_bready),
        .log_data(logging_b_payload)
    );

endmodule