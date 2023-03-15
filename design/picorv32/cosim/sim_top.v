`timescale 1 ns / 1 ns

`include "axi.vh"

module sim_top;

    reg [512*8-1:0] dumpfile;

    initial begin
        if ($value$plusargs("dumpfile=%s", dumpfile)) begin
            $dumpfile(dumpfile);
            $dumpvars();
        end
    end

    reg clk = 0, rst = 1;

    always #5 clk = ~clk;

    initial begin
        #30 rst = 0;
    end

    `AXI4_WIRE(mem_axi, 32, 64, 1);
    `AXI4LITE_WIRE(mmio_axi, 32, 32);

    `AXI4_WIRE(scan_dma, 40, 64, 1);
    `AXI4_WIRE(rammodel, 32, 32, 1);
    `AXI4_WIRE(rammodel_resized, 32, 64, 1);

    EMU_SYSTEM u_emu_system(
        .EMU_HOST_CLK                                   (clk),
        .EMU_HOST_RST                                   (rst),

        `AXI4LITE_CONNECT   (EMU_CTRL, mmio_axi),
        `AXI4_CONNECT_NO_ID (EMU_SCAN_DMA_AXI, scan_dma),
        `AXI4_CONNECT       (EMU_AXI_u_rammodel_backend_host_axi, rammodel)
    );

    axi_adapter #(
        .ADDR_WIDTH     (32),
        .S_DATA_WIDTH   (32),
        .M_DATA_WIDTH   (64),
        .ID_WIDTH       (1)
    ) rammodel_adapter (
        .clk            (clk),
        .rst            (rst),
        `AXI4_CONNECT   (s_axi, rammodel),
        `AXI4_CONNECT   (m_axi, rammodel_resized)
    );

    axi_interconnect_wrap_2x1 #(
        .DATA_WIDTH     (64),
        .ADDR_WIDTH     (32),
        .ID_WIDTH       (1),
        .M00_BASE_ADDR  ('h00000000),
        .M00_ADDR_WIDTH (32)
    ) mem_xbar (
        .clk            (clk),
        .rst            (rst),

        `AXI4_CONNECT(s00_axi, scan_dma),
        `AXI4_CONNECT(s01_axi, rammodel_resized),
        `AXI4_CONNECT(m00_axi, mem_axi)
    );

    cosim_bfm #(
        .MEM_ADDR_WIDTH (32),
        .MEM_DATA_WIDTH (64),
        .MEM_ID_WIDTH   (1),
        .MEM_SIZE       (64'h40000000)
    ) u_cosim_bfm (
        .clk                (clk),
        .rst                (rst),

        `AXI4_CONNECT       (mem_axi, mem_axi),
        `AXI4LITE_CONNECT   (mmio_axi, mmio_axi)
    );

endmodule
