`timescale 1ns / 1ps

`include "axi.vh"

module axi_stall_s #(
    parameter   ADDR_WIDTH              = 32,
    parameter   DATA_WIDTH              = 64,
    parameter   ID_WIDTH                = 4
)(
    input                       clk,
    input                       resetn,

    `AXI4_SLAVE_IF              (s, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (m, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input                       stall
);

    ready_valid_stall_s #(
        .DATA_WIDTH(`AXI4_AW_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_stall_aw (
        .s_valid    (s_awvalid),
        .s_ready    (s_awready),
        .s_data     (`AXI4_AW_PAYLOAD(s)),
        .m_valid    (m_awvalid),
        .m_ready    (m_awready),
        .m_data     (`AXI4_AW_PAYLOAD(m)),
        .stall      (stall)
    );

    ready_valid_stall_s #(
        .DATA_WIDTH(`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_stall_w (
        .s_valid    (s_wvalid),
        .s_ready    (s_wready),
        .s_data     (`AXI4_W_PAYLOAD(s)),
        .m_valid    (m_wvalid),
        .m_ready    (m_wready),
        .m_data     (`AXI4_W_PAYLOAD(m)),
        .stall      (stall)
    );

    ready_valid_stall_m #(
        .DATA_WIDTH(`AXI4_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_stall_b (
        .m_valid    (s_bvalid),
        .m_ready    (s_bready),
        .m_data     (`AXI4_B_PAYLOAD(s)),
        .s_valid    (m_bvalid),
        .s_ready    (m_bready),
        .s_data     (`AXI4_B_PAYLOAD(m)),
        .stall      (stall)
    );

    ready_valid_stall_s #(
        .DATA_WIDTH(`AXI4_AR_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_stall_ar (
        .s_valid    (s_arvalid),
        .s_ready    (s_arready),
        .s_data     (`AXI4_AR_PAYLOAD(s)),
        .m_valid    (m_arvalid),
        .m_ready    (m_arready),
        .m_data     (`AXI4_AR_PAYLOAD(m)),
        .stall      (stall)
    );

    ready_valid_stall_m #(
        .DATA_WIDTH(`AXI4_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    s_stall_r (
        .m_valid    (s_rvalid),
        .m_ready    (s_rready),
        .m_data     (`AXI4_R_PAYLOAD(s)),
        .s_valid    (m_rvalid),
        .s_ready    (m_rready),
        .s_data     (`AXI4_R_PAYLOAD(m)),
        .stall      (stall)
    );

endmodule
