`timescale 1 ns / 1 ns

`include "axi.vh"

module emu_system_wrap(
    input           host_clk,
    input           host_rst,

    `AXI4LITE_SLAVE_IF(mmio, 32, 32),
    `AXI4_MASTER_IF(mem, 32, 32, 1)
);

    `AXI4_WIRE(scan_dma, 40, 64, 1);
    `AXI4_WIRE(scan_dma_conv, 32, 32, 1);
    `AXI4_WIRE(rammodel, 32, 64, 1);
    `AXI4_WIRE(rammodel_conv, 32, 32, 1);

    EMU_SYSTEM u_emu_system(
        .EMU_HOST_CLK                                   (host_clk),
        .EMU_HOST_RST                                   (host_rst),

        `AXI4LITE_CONNECT(EMU_CTRL, mmio),
        `AXI4_CONNECT_NO_ID(EMU_SCAN_DMA_AXI, scan_dma),
        `AXI4_CONNECT(EMU_AXI_u_rammodel_backend_host_axi, rammodel)
    );

    assign EMU_SCAN_DMA_arid = 0;
    assign EMU_SCAN_DMA_awid = 0;

    axi_adapter #(
        .ADDR_WIDTH     (32),
        .S_DATA_WIDTH   (64),
        .M_DATA_WIDTH   (32),
        .ID_WIDTH       (1)
    ) scan_dma_adapter (
        .clk            (host_clk),
        .rst            (host_rst),

        `AXI4_CONNECT(s_axi, scan_dma),
        `AXI4_CONNECT(m_axi, scan_dma_conv)
    );

    axi_adapter #(
        .ADDR_WIDTH     (32),
        .S_DATA_WIDTH   (64),
        .M_DATA_WIDTH   (32),
        .ID_WIDTH       (1)
    ) rammodel_adapter (
        .clk            (host_clk),
        .rst            (host_rst),

        `AXI4_CONNECT(s_axi, rammodel),
        `AXI4_CONNECT(m_axi, rammodel_conv)
    );

    axi_interconnect_wrap_2x1 #(
        .DATA_WIDTH     (32),
        .ADDR_WIDTH     (32),
        .ID_WIDTH       (1),
        .M00_BASE_ADDR  ('h00000000),
        .M00_ADDR_WIDTH (32)
    ) mem_xbar (
        .clk            (host_clk),
        .rst            (host_rst),

        `AXI4_CONNECT(s00_axi, scan_dma_conv),
        `AXI4_CONNECT(s01_axi, rammodel_conv),
        `AXI4_CONNECT(m00_axi, mem)
    );

endmodule
