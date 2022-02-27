`resetall
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

    emulib_register_slice #(
        .DATA_WIDTH(`AXI4_AW_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_aw (
        .clk        (clk),
        .resetn     (resetn),
        .s_valid    (s_awvalid),
        .s_ready    (s_awready),
        .s_data     (`AXI4_AW_PAYLOAD(s)),
        .m_valid    (m_awvalid),
        .m_ready    (m_awready),
        .m_data     (`AXI4_AW_PAYLOAD(m))
    );

    emulib_register_slice #(
        .DATA_WIDTH(`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_w (
        .clk        (clk),
        .resetn     (resetn),
        .s_valid    (s_wvalid),
        .s_ready    (s_wready),
        .s_data     (`AXI4_W_PAYLOAD(s)),
        .m_valid    (m_wvalid),
        .m_ready    (m_wready),
        .m_data     (`AXI4_W_PAYLOAD(m))
    );

    emulib_register_slice #(
        .DATA_WIDTH(`AXI4_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_b (
        .clk        (clk),
        .resetn     (resetn),
        .s_valid    (m_bvalid),
        .s_ready    (m_bready),
        .s_data     (`AXI4_B_PAYLOAD(m)),
        .m_valid    (s_bvalid),
        .m_ready    (s_bready),
        .m_data     (`AXI4_B_PAYLOAD(s))
    );

    emulib_register_slice #(
        .DATA_WIDTH(`AXI4_AR_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_ar (
        .clk        (clk),
        .resetn     (resetn),
        .s_valid    (s_arvalid),
        .s_ready    (s_arready),
        .s_data     (`AXI4_AR_PAYLOAD(s)),
        .m_valid    (m_arvalid),
        .m_ready    (m_arready),
        .m_data     (`AXI4_AR_PAYLOAD(m))
    );

    emulib_register_slice #(
        .DATA_WIDTH(`AXI4_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    )
    slice_r (
        .clk        (clk),
        .resetn     (resetn),
        .s_valid    (m_rvalid),
        .s_ready    (m_rready),
        .s_data     (`AXI4_R_PAYLOAD(m)),
        .m_valid    (s_rvalid),
        .m_ready    (s_rready),
        .m_data     (`AXI4_R_PAYLOAD(s))
    );

endmodule

`resetall
