`timescale 1ns / 1ps
`include "axi.vh"

module test #(
    // must be consistent with emu_top
    parameter   DMA_ADDR_WIDTH      = 32,
    parameter   DMA_DATA_WIDTH      = 64,
    parameter   MMIO_ADDR_WIDTH     = 32,
    parameter   MMIO_DATA_WIDTH     = 32,
    parameter   DMA_ID_WIDTH        = 1,
    parameter   MAX_R_INFLIGHT  = 1,
    parameter   MAX_W_INFLIGHT  = 1
)(

    input                       host_clk,
    input                       host_rst,

    output                      target_clk,
    input                       target_rst,

    input                       host_dma_awvalid,
    output                      host_dma_awready,
    input   [DMA_ADDR_WIDTH-1:0]    host_dma_awaddr,
    input   [DMA_ID_WIDTH-1:0]      host_dma_awid,
    input   [7:0]               host_dma_awlen,
    input   [2:0]               host_dma_awsize,
    input   [1:0]               host_dma_awburst,
    input   [0:0]               host_dma_awlock,
    input   [3:0]               host_dma_awcache,
    input   [2:0]               host_dma_awprot,
    input   [3:0]               host_dma_awqos,
    input   [3:0]               host_dma_awregion,

    input                       host_dma_wvalid,
    output                      host_dma_wready,
    input   [DMA_DATA_WIDTH-1:0]    host_dma_wdata,
    input   [DMA_DATA_WIDTH/8-1:0]  host_dma_wstrb,
    input                       host_dma_wlast,

    output                      host_dma_bvalid,
    input                       host_dma_bready,
    output  [1:0]               host_dma_bresp,
    output  [DMA_ID_WIDTH-1:0]      host_dma_bid,

    input                       host_dma_arvalid,
    output                      host_dma_arready,
    input   [DMA_ADDR_WIDTH-1:0]    host_dma_araddr,
    input   [DMA_ID_WIDTH-1:0]      host_dma_arid,
    input   [7:0]               host_dma_arlen,
    input   [2:0]               host_dma_arsize,
    input   [1:0]               host_dma_arburst,
    input   [0:0]               host_dma_arlock,
    input   [3:0]               host_dma_arcache,
    input   [2:0]               host_dma_arprot,
    input   [3:0]               host_dma_arqos,
    input   [3:0]               host_dma_arregion,

    output                      host_dma_rvalid,
    input                       host_dma_rready,
    output  [DMA_DATA_WIDTH-1:0]    host_dma_rdata,
    output  [1:0]               host_dma_rresp,
    output  [DMA_ID_WIDTH-1:0]      host_dma_rid,
    output                      host_dma_rlast,

    output                      host_mmio_awvalid,
    input                       host_mmio_awready,
    output  [DMA_ADDR_WIDTH-1:0]    host_mmio_awaddr,
   
    output                      host_mmio_wvalid,
    input                       host_mmio_wready,
    output  [MMIO_DATA_WIDTH-1:0]    host_mmio_wdata,
    output  [MMIO_DATA_WIDTH/8-1:0]  host_mmio_wstrb,
    
    input                       host_mmio_bvalid,
    output                      host_mmio_bready,
    input   [1:0]               host_mmio_bresp,

    output                      host_mmio_arvalid,
    input                       host_mmio_arready,
    output  [MMIO_ADDR_WIDTH-1:0]    host_mmio_araddr,
    
    input                       host_mmio_rvalid,
    output                      host_mmio_rready,
    input   [MMIO_DATA_WIDTH-1:0]    host_mmio_rdata,
    input   [1:0]               host_mmio_rresp,
    
    output                           target_dma_awvalid,
    input                            target_dma_awready,
    output  [DMA_ADDR_WIDTH-1:0]     target_dma_awaddr,
    output                           target_dma_awid,
    output  [7:0]                    target_dma_awlen,
    output  [2:0]                    target_dma_awsize,
    output  [1:0]                    target_dma_awburst,
    output  [0:0]                    target_dma_awlock,
    output  [3:0]                    target_dma_awcache,
    output  [2:0]                    target_dma_awprot,
    output  [3:0]                    target_dma_awqos,
    output  [3:0]                    target_dma_awregion,

    output                           target_dma_wvalid,
    input                            target_dma_wready,
    output  [DMA_DATA_WIDTH-1:0]     target_dma_wdata,
    output  [DMA_DATA_WIDTH/8-1:0]   target_dma_wstrb,
    output                           target_dma_wlast,

    input                            target_dma_bvalid,
    output                           target_dma_bready,
    input   [1:0]                    target_dma_bresp,
    input                            target_dma_bid,

    output                           target_dma_arvalid,
    input                            target_dma_arready,
    output  [DMA_ADDR_WIDTH-1:0]     target_dma_araddr,
    output                           target_dma_arid,
    output  [7:0]                    target_dma_arlen,
    output  [2:0]                    target_dma_arsize,
    output  [1:0]                    target_dma_arburst,
    output  [0:0]                    target_dma_arlock,
    output  [3:0]                    target_dma_arcache,
    output  [2:0]                    target_dma_arprot,
    output  [3:0]                    target_dma_arqos,
    output  [3:0]                    target_dma_arregion,

    input                            target_dma_rvalid,
    output                           target_dma_rready,
    input   [DMA_DATA_WIDTH-1:0]     target_dma_rdata,
    input   [1:0]                    target_dma_rresp,
    input                            target_dma_rid,
    input                            target_dma_rlast,

    `AXI4LITE_SLAVE_IF          (target_mmio,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH),

    input                       ff_scan,
    input                       ff_dir,
    input                       ff_sdi,
    output                      ff_sdo,
    input                       ram_scan_reset,
    input                       ram_scan,
    input                       ram_dir,
    input                       ram_sdi,
    output                      ram_sdo,

    input                       run_mode,
    input                       scan_mode,
    output                      idle

);

    wire tick;

    EMU_SYSTEM emu_dut (
        .rst                (target_rst),
        
        .EMU_HOST_CLK       (host_clk),
        .EMU_HOST_RST       (host_rst),
        .EMU_FF_SE          (ff_scan),
        .EMU_FF_DI          (ff_dir ? ff_sdi : ff_sdo),
        .EMU_FF_DO          (ff_sdo),
        .EMU_RAM_SR         (ram_scan_reset),
        .EMU_RAM_SE         (ram_scan),
        .EMU_RAM_SD         (ram_dir),
        .EMU_RAM_DI         (ram_sdi),
        .EMU_RAM_DO         (ram_sdo),
        .EMU_RUN_MODE       (run_mode),
        .EMU_SCAN_MODE      (scan_mode),
        .EMU_IDLE           (idle),
        .EMU_TICK           (tick),

        //`AXI4_CONNECT (host_dma_axi, host_dma),
        //`AXI4LITE_CONNECT (host_mmio_axi, host_mmio),

        `AXI4_CONNECT (target_dma, target_dma),
        `AXI4LITE_CONNECT (target_mmio, target_mmio)

    );

    ClockGate target_clk_gate (
        .CLK(host_clk),
        .EN(tick && run_mode),
        .OCLK(target_clk)
    );

endmodule
