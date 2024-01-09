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
    wire [2:0]                       mmio_arreq_prot;
    wire [MMIO_ADDR_WIDTH-1:0]       mmio_arreq_addr;

    wire                             mmio_awreq_valid;
    wire [2:0]                       mmio_awreq_prot;
    wire [MMIO_ADDR_WIDTH-1:0]       mmio_awreq_addr;

    wire                             mmio_wreq_valid;
    wire [MMIO_DATA_WIDTH-1:0]       mmio_wreq_data;
    wire [MMIO_DATA_WIDTH/8-1:0]     mmio_wreq_strb;

    wire                             mmio_breq_valid;
    wire                             mmio_rreq_valid;
    wire [MMIO_DATA_WIDTH-1:0]       mmio_rresp_data;
    wire [1:0]                       mmio_rresp_resp;
    wire [1:0]                       mmio_bresp_resp;

    //// DMA
    wire                             dma_arreq_valid;
    wire                             dma_arreq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_arreq_id;
    wire [DMA_ADDR_WIDTH-1:0]        dma_arreq_addr;
    wire [7:0]                       dma_arreq_len;
    wire [2:0]                       dma_arreq_size;
    wire [2:0]                       dma_arreq_prot;
    wire [1:0]                       dma_arreq_burst;

    wire                             dma_awreq_valid;
    wire                             dma_awreq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_awreq_id;
    wire [DMA_ADDR_WIDTH-1:0]        dma_awreq_addr;
    wire [7:0]                       dma_awreq_len;
    wire [2:0]                       dma_awreq_size;
    wire [1:0]                       dma_awreq_burst;
    wire [2:0]                       dma_awreq_prot;

    wire                             dma_wreq_valid;
    wire                             dma_wreq_ready;
    wire [DMA_DATA_WIDTH-1:0]        dma_wreq_data;
    wire [DMA_DATA_WIDTH/8-1:0]      dma_wreq_strb;
    wire                             dma_wreq_last;

    wire                             dma_breq_valid;
    wire                             dma_breq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_breq_id;
    wire [1:0]                       dma_breq_resp;

    wire                             dma_rreq_valid;
    wire                             dma_rreq_ready;
    wire [DMA_ID_WIDTH-1:0]          dma_rreq_id;
    wire [DMA_DATA_WIDTH-1:0]        dma_rreq_data;
    wire [1:0]                       dma_rreq_rresp;
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
        .mmio_arreq_prot             (mmio_arreq_prot),
        .mmio_arreq_addr             (mmio_arreq_addr),

        .mmio_awreq_valid            (mmio_awreq_valid),
        .mmio_awreq_prot             (mmio_awreq_prot),
        .mmio_awreq_addr             (mmio_awreq_addr),

        .mmio_wreq_valid             (mmio_wreq_valid),
        .mmio_wreq_data              (mmio_wreq_data),
        .mmio_wreq_strb              (mmio_wreq_strb),

        .mmio_breq_valid             (mmio_breq_valid),
        .mmio_rreq_valid             (mmio_rreq_valid),
        .mmio_rresp_data             (mmio_rresp_data),
        .mmio_rresp_resp             (mmio_rresp_resp),
        .mmio_bresp_resp             (mmio_bresp_resp),

        //// DMA
        .dma_arreq_valid            (dma_arreq_valid),
        .dma_arreq_ready            (dma_arreq_ready),
        .dma_arreq_id               (dma_arreq_id),
        .dma_arreq_addr             (dma_arreq_addr),
        .dma_arreq_len              (dma_arreq_len),
        .dma_arreq_size             (dma_arreq_size),
        .dma_arreq_burst            (dma_arreq_burst),
        .dma_arreq_prot             (dma_arreq_prot),

        .dma_awreq_ready            (dma_awreq_ready),
        .dma_awreq_valid            (dma_awreq_valid),
        .dma_awreq_id               (dma_awreq_id),
        .dma_awreq_addr             (dma_awreq_addr),
        .dma_awreq_len              (dma_awreq_len),
        .dma_awreq_size             (dma_awreq_size),
        .dma_awreq_burst            (dma_awreq_burst),
        .dma_awreq_prot             (dma_awreq_prot),

        .dma_wreq_ready             (dma_wreq_ready),
        .dma_wreq_valid             (dma_wreq_valid),
        .dma_wreq_data              (dma_wreq_data),
        .dma_wreq_strb              (dma_wreq_strb),
        .dma_wreq_last              (dma_wreq_last),

        .dma_breq_ready             (dma_breq_ready),
        .dma_breq_valid             (dma_breq_valid),
        .dma_breq_id                (dma_breq_id),
        .dma_breq_bresp             (dma_breq_resp),

        .dma_rreq_ready             (dma_rreq_ready),
        .dma_rreq_valid             (dma_rreq_valid),
        .dma_rreq_id                (dma_rreq_id),
        .dma_rreq_data              (dma_rreq_data),
        .dma_rreq_last              (dma_rreq_last),
        .dma_rreq_rresp             (dma_rreq_rresp)
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
        .mmio_arreq_prot             (mmio_arreq_prot),
        .mmio_arreq_addr             (mmio_arreq_addr),

        .mmio_awreq_valid            (mmio_awreq_valid),
        .mmio_awreq_prot             (mmio_awreq_prot),
        .mmio_awreq_addr             (mmio_awreq_addr),

        .mmio_wreq_valid             (mmio_wreq_valid),
        .mmio_wreq_data              (mmio_wreq_data),
        .mmio_wreq_strb              (mmio_wreq_strb),

        .mmio_breq_valid             (mmio_breq_valid),

        .mmio_bresp_resp             (mmio_bresp_resp),

        .mmio_rreq_valid             (mmio_rreq_valid),

        .mmio_rresp_resp             (mmio_rresp_resp),
        .mmio_rresp_data             (mmio_rresp_data),

        //// DMA

        .dma_port_out_arvalid            (dma_arreq_valid),
        .dma_port_in_arready             (dma_arreq_ready),
        .dma_port_out_arid               (dma_arreq_id),
        .dma_port_out_araddr             (dma_arreq_addr),
        .dma_port_out_arlen              (dma_arreq_len),
        .dma_port_out_arsize             (dma_arreq_size),
        .dma_port_out_arburst            (dma_arreq_burst),
        .dma_port_out_arprot             (dma_arreq_prot),

        .dma_port_in_awready            (dma_awreq_ready),
        .dma_port_out_awvalid            (dma_awreq_valid),
        .dma_port_out_awid               (dma_awreq_id),
        .dma_port_out_awaddr             (dma_awreq_addr),
        .dma_port_out_awlen              (dma_awreq_len),
        .dma_port_out_awsize             (dma_awreq_size),
        .dma_port_out_awprot             (dma_awreq_prot),
        .dma_port_out_awburst            (dma_awreq_burst),

        .dma_port_in_wready             (dma_wreq_ready),
        .dma_port_out_wvalid             (dma_wreq_valid),
        .dma_port_out_wdata              (dma_wreq_data),
        .dma_port_out_wstrb              (dma_wreq_strb),
        .dma_port_out_wlast              (dma_wreq_last),

        .dma_port_out_bready             (dma_breq_ready),
        .dma_port_in_bvalid             (dma_breq_valid),
        .dma_port_in_bid                (dma_breq_id),
        .dma_port_in_bresp              (dma_breq_resp),

        .dma_port_out_rready             (dma_rreq_ready),
        .dma_port_in_rvalid             (dma_rreq_valid),
        .dma_port_in_rid                (dma_rreq_id),
        .dma_port_in_rdata              (dma_rreq_data),
        .dma_port_in_rresp              (dma_rreq_rresp),
        .dma_port_in_rlast              (dma_rreq_last)
    );

endmodule