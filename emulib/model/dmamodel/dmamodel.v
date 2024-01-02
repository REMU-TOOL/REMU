`timescale 1ns / 1ps
`include "axi.vh"
`include "axi_custom.vh"


(* __emu_model_type = "dmamodel" *)
module EmuDMA #(
    parameter  MMIO_ADDR_WIDTH   = 32,
    parameter  MMIO_DATA_WIDTH   = 32,
    parameter  DMA_ADDR_WIDTH   = 32,
    parameter  DMA_DATA_WIDTH   = 64,
    parameter  DMA_ID_WIDTH     = 4,
    parameter   MAX_R_INFLIGHT  = 1,
    parameter   MAX_W_INFLIGHT  = 1
)(
    input  wire             clk,
    input  wire             rst,
    `AXI4LITE_SLAVE_IF          (s_mmio_axi,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH),
    `AXI4_MASTER_IF             (m_dma_axi,     DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH)
);


    initial begin
        if (DMA_ADDR_WIDTH <= 0 || MMIO_ADDR_WIDTH <= 0) begin
            $display("%m: ADDR_WIDTH must be greater than 0");
            $finish;
        end
        if (DMA_ADDR_WIDTH > 64 || MMIO_ADDR_WIDTH > 64) begin
            $display("%m: ADDR_WIDTH must not be greater than 64");
            $finish;
        end
        if (DMA_DATA_WIDTH != 8 &&
            DMA_DATA_WIDTH != 16 &&
            DMA_DATA_WIDTH != 32 &&
            DMA_DATA_WIDTH != 64 &&
            DMA_DATA_WIDTH != 128 &&
            DMA_DATA_WIDTH != 256 &&
            DMA_DATA_WIDTH != 512 &&
            DMA_DATA_WIDTH != 1024) begin
            $display("%m: DMA_DATA_WIDTH must be 8, 16, 32, 64, 128, 256, 512 or 1024");
            $finish;
        end
        if (MMIO_DATA_WIDTH != 8 &&
            MMIO_DATA_WIDTH != 16 &&
            MMIO_DATA_WIDTH != 32 &&
            MMIO_DATA_WIDTH != 64 &&
            MMIO_DATA_WIDTH != 128) begin
            $display("%m: MMIO_DATA_WIDTH must be 8, 16, 32, 64, 128");
            $finish;
        end
        if (DMA_ID_WIDTH <= 0) begin
            $display("%m: ID_WIDTH must be greater than 0");
            $finish;
        end
        if (DMA_ID_WIDTH > 8) begin
            $display("%m: ID_WIDTH must not be greater than 8");
            $finish;
        end
    end

    wire                             mmio_arreq_valid;
    wire [MMIO_ADDR_WIDTH-1:0]       mmio_arreq_addr;

    wire                             mmio_awreq_valid;
    wire [MMIO_ADDR_WIDTH-1:0]       mmio_awreq_addr;

    wire                             mmio_wreq_valid;
    wire [MMIO_DATA_WIDTH-1:0]       mmio_wreq_data;
    wire [MMIO_DATA_WIDTH/8-1:0]     mmio_wreq_strb;

    wire                             mmio_breq_valid;
    wire                             mmio_rreq_valid;
    wire [MMIO_DATA_WIDTH-1:0]       mmio_rresp_data;

    //// DMA
    wire                             dma_arreq_valid;
    wire                             dma_arreq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_arreq_id;
    wire [DMA_ADDR_WIDTH-1:0]        dma_arreq_addr;
    wire [7:0]                       dma_arreq_len;
    wire [2:0]                       dma_arreq_size;
    wire [1:0]                       dma_arreq_burst;

    wire                             dma_awreq_valid;
    wire                             dma_awreq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_awreq_id;
    wire [DMA_ADDR_WIDTH-1:0]        dma_awreq_addr;
    wire [7:0]                       dma_awreq_len;
    wire [2:0]                       dma_awreq_size;
    wire [1:0]                       dma_awreq_burst;

    wire                             dma_wreq_valid;
    wire                             dma_wreq_ready;
    wire [DMA_DATA_WIDTH-1:0]        dma_wreq_data;
    wire [DMA_DATA_WIDTH/8-1:0]      dma_wreq_strb;
    wire                             dma_wreq_last;

    wire                             dma_breq_valid;
    wire                             dma_breq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_breq_id;
    wire [1:0]                       dma_breq_bresp;

    wire                             dma_rreq_valid;
    wire                             dma_rreq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_rreq_id;
    wire [DMA_DATA_WIDTH-1:0]        dma_rreq_data;
    wire                             dma_rreq_last;
    
    emulib_dmamodel_frontend #(
        .MMIO_ADDR_WIDTH     (MMIO_ADDR_WIDTH),
        .MMIO_DATA_WIDTH     (MMIO_DATA_WIDTH),
        .DMA_ADDR_WIDTH      (DMA_ADDR_WIDTH),
        .DMA_DATA_WIDTH      (DMA_DATA_WIDTH),
        .DMA_ID_WIDTH        (DMA_ID_WIDTH)
    )u_dmamodel_frontend(
        .clk                    (clk),
        .rst                    (rst),

        `AXI4LITE_CONNECT       (target_mmio_axi, s_mmio_axi),
        `AXI4_CONNECT           (target_dma_axi, m_dma_axi),

        .mmio_arreq_valid            (mmio_arreq_valid),
        .mmio_arreq_addr             (mmio_arreq_addr),

        .mmio_awreq_valid            (mmio_awreq_valid),
        .mmio_awreq_addr             (mmio_awreq_addr),

        .mmio_wreq_valid             (mmio_wreq_valid),
        .mmio_wreq_data              (mmio_wreq_data),
        .mmio_wreq_strb              (mmio_wreq_strb),

        .mmio_breq_valid             (mmio_breq_valid),
        .mmio_rreq_valid             (mmio_rreq_valid),
        .mmio_rresp_data             (mmio_rresp_data),

        //// DMA
        .dma_arreq_valid            (dma_arreq_valid),
        .dma_arreq_ready            (dma_arreq_ready),
        .dma_arreq_id               (dma_arreq_id),
        .dma_arreq_addr             (dma_arreq_addr),
        .dma_arreq_len              (dma_arreq_len),
        .dma_arreq_size             (dma_arreq_size),
        .dma_arreq_burst            (dma_arreq_burst),

        .dma_awreq_ready            (dma_awreq_ready),
        .dma_awreq_valid            (dma_awreq_valid),
        .dma_awreq_id               (dma_awreq_id),
        .dma_awreq_addr             (dma_awreq_addr),
        .dma_awreq_len              (dma_awreq_len),
        .dma_awreq_size             (dma_awreq_size),
        .dma_awreq_burst            (dma_awreq_burst),

        .dma_wreq_ready             (dma_wreq_ready),
        .dma_wreq_valid             (dma_wreq_valid),
        .dma_wreq_data              (dma_wreq_data),
        .dma_wreq_strb              (dma_wreq_strb),
        .dma_wreq_last              (dma_wreq_last),

        .dma_breq_ready             (dma_breq_ready),
        .dma_breq_valid             (dma_breq_valid),
        .dma_breq_id                (dma_breq_id),

        .dma_rreq_ready             (dma_rreq_ready),
        .dma_rreq_valid             (dma_rreq_valid),
        .dma_rreq_id                (dma_rreq_id),
        .dma_rreq_data              (dma_rreq_data),
        .dma_rreq_last              (dma_rreq_last)
    );

    emulib_dmamodel_backend #(
        .MMIO_ADDR_WIDTH     (MMIO_ADDR_WIDTH),
        .MMIO_DATA_WIDTH     (MMIO_DATA_WIDTH),
        .DMA_ADDR_WIDTH      (DMA_ADDR_WIDTH),
        .DMA_DATA_WIDTH      (DMA_DATA_WIDTH),
        .DMA_ID_WIDTH        (DMA_ID_WIDTH)
    )u_dmamodel_backend(
        .clk                    (clk),
        .rst                    (rst),

        .mmio_arreq_valid            (mmio_arreq_valid),
        .mmio_arreq_addr             (mmio_arreq_addr),

        .mmio_awreq_valid            (mmio_awreq_valid),
        .mmio_awreq_addr             (mmio_awreq_addr),

        .mmio_wreq_valid             (mmio_wreq_valid),
        .mmio_wreq_data              (mmio_wreq_data),
        .mmio_wreq_strb              (mmio_wreq_strb),

        .mmio_breq_valid             (mmio_breq_valid),
        .mmio_rreq_valid             (mmio_rreq_valid),
        .mmio_rresp_data             (mmio_rresp_data),

        //// DMA
        .dma_port_arvalid            (dma_arreq_valid),
        .dma_port_arready            (dma_arreq_ready),
        .dma_port_arid               (dma_arreq_id),
        .dma_port_araddr             (dma_arreq_addr),
        .dma_port_arlen              (dma_arreq_len),
        .dma_port_arsize             (dma_arreq_size),
        .dma_port_arburst            (dma_arreq_burst),

        .dma_port_awready            (dma_awreq_ready),
        .dma_port_awvalid            (dma_awreq_valid),
        .dma_port_awid               (dma_awreq_id),
        .dma_port_awaddr             (dma_awreq_addr),
        .dma_port_awlen              (dma_awreq_len),
        .dma_port_awsize             (dma_awreq_size),
        .dma_port_awburst            (dma_awreq_burst),

        .dma_port_wready             (dma_wreq_ready),
        .dma_port_wvalid             (dma_wreq_valid),
        .dma_port_wdata              (dma_wreq_data),
        .dma_port_wstrb              (dma_wreq_strb),
        .dma_port_wlast              (dma_wreq_last),

        .dma_port_bready             (dma_breq_ready),
        .dma_port_bvalid             (dma_breq_valid),
        .dma_port_bid                (dma_breq_id),

        .dma_port_rready             (dma_rreq_ready),
        .dma_port_rvalid             (dma_rreq_valid),
        .dma_port_rid                (dma_rreq_id),
        .dma_port_rdata              (dma_rreq_data),
        .dma_port_rlast              (dma_rreq_last)
    );

endmodule