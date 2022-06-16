`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"

module emulib_axi_register_slice #(
    parameter   ADDR_WIDTH              = 32,
    parameter   DATA_WIDTH              = 64,
    parameter   ID_WIDTH                = 4
)(
    input  wire                 clk,
    input  wire                 resetn,
    `AXI4_SLAVE_IF              (s, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (m, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)
);

    emulib_pipeline_skid_buffer #(
        .DATA_WIDTH(`AXI4_AW_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_aw (
        .clk        (clk),
        .rst        (!resetn),
        .i_valid    (s_awvalid),
        .i_ready    (s_awready),
        .i_data     (`AXI4_AW_PAYLOAD(s)),
        .o_valid    (m_awvalid),
        .o_ready    (m_awready),
        .o_data     (`AXI4_AW_PAYLOAD(m))
    );

    emulib_pipeline_skid_buffer #(
        .DATA_WIDTH(`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_w (
        .clk        (clk),
        .rst        (!resetn),
        .i_valid    (s_wvalid),
        .i_ready    (s_wready),
        .i_data     (`AXI4_W_PAYLOAD(s)),
        .o_valid    (m_wvalid),
        .o_ready    (m_wready),
        .o_data     (`AXI4_W_PAYLOAD(m))
    );

    emulib_pipeline_skid_buffer #(
        .DATA_WIDTH(`AXI4_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_b (
        .clk        (clk),
        .rst        (!resetn),
        .i_valid    (m_bvalid),
        .i_ready    (m_bready),
        .i_data     (`AXI4_B_PAYLOAD(m)),
        .o_valid    (s_bvalid),
        .o_ready    (s_bready),
        .o_data     (`AXI4_B_PAYLOAD(s))
    );

    emulib_pipeline_skid_buffer #(
        .DATA_WIDTH(`AXI4_AR_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_ar (
        .clk        (clk),
        .rst        (!resetn),
        .i_valid    (s_arvalid),
        .i_ready    (s_arready),
        .i_data     (`AXI4_AR_PAYLOAD(s)),
        .o_valid    (m_arvalid),
        .o_ready    (m_arready),
        .o_data     (`AXI4_AR_PAYLOAD(m))
    );

    emulib_pipeline_skid_buffer #(
        .DATA_WIDTH(`AXI4_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_r (
        .clk        (clk),
        .rst        (!resetn),
        .i_valid    (m_rvalid),
        .i_ready    (m_rready),
        .i_data     (`AXI4_R_PAYLOAD(m)),
        .o_valid    (s_rvalid),
        .o_ready    (s_rready),
        .o_data     (`AXI4_R_PAYLOAD(s))
    );

endmodule

`default_nettype wire
