`timescale 1ns / 1ps
`include "axi.vh"
`include "axi_custom.vh"


(* __emu_model_type = "dmamodel" *)
module EmuDMA #(
    parameter  MMIO_ADDR_WIDTH   = 32,
    parameter  MMIO_DATA_WIDTH   = 64,
    parameter  MMIO_ID_WIDTH     = 4,
    parameter  DMA_ADDR_WIDTH   = 32,
    parameter  DMA_DATA_WIDTH   = 64,
    parameter  DMA_ID_WIDTH     = 4,
)(
    input  wire             clk,
    input  wire             rst,
    `AXI4LITE_SLAVE_IF          (s_mmio_axi,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH, MMIO_ID_WIDTH),
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
        if (MMIO_ID_WIDTH <= 0 || DMA_ID_WIDTH <= 0) begin
            $display("%m: ID_WIDTH must be greater than 0");
            $finish;
        end
        if (MMIO_ID_WIDTH > 8 || DMA_ID_WIDTH > 8) begin
            $display("%m: ID_WIDTH must not be greater than 8");
            $finish;
        end
    end

    wire                             mmio_arreq_valid;
    //wire [MMIO_ID_WIDTH-1:0]         mmio_arreq_id;
    wire [MMIO_ADDR_WIDTH-1:0]       mmio_arreq_addr;
    //wire [7:0]                       mmio_arreq_len;
    //wire [2:0]                       mmio_arreq_size;
    //wire [1:0]                       mmio_arreq_burst;

    wire                             mmio_awreq_valid;
    //wire [MMIO_ID_WIDTH-1:0]         mmio_awreq_id;
    wire [MMIO_ADDR_WIDTH-1:0]       mmio_awreq_addr;
    //wire [7:0]                       mmio_awreq_len;
    //wire [2:0]                       mmio_awreq_size;
    //wire [1:0]                       mmio_awreq_burst;

    wire                             mmio_wreq_valid;
    wire [MMIO_DATA_WIDTH-1:0]       mmio_wreq_data;
    wire [MMIO_DATA_WIDTH/8-1:0]     mmio_wreq_strb;
    //wire                             mmio_wreq_last;

    wire                             mmio_breq_valid;
    //wire [MMIO_ID_WIDTH-1:0]         mmio_breq_id;

    wire                             mmio_rreq_valid;
    //wire [MMIO_ID_WIDTH-1:0]         mmio_rreq_id;

    wire [MMIO_DATA_WIDTH-1:0]       mmio_rresp_data;
    //wire                             mmio_rresp_last;
    
    emulib_dmamodel_frontend #(
        .MMIO_ADDR_WIDTH     (MMIO_ADDR_WIDTH),
        .MMIO_DATA_WIDTH     (MMIO_DATA_WIDTH),
        .MMIO_ID_WIDTH       (MMIO_ID_WIDTH),
        .DMA_ADDR_WIDTH      (DMA_ADDR_WIDTH),
        .DMA_DATA_WIDTH      (DMA_DATA_WIDTH),
        .DMA_ID_WIDTH        (DMA_ID_WIDTH)
    )(
        .clk                    (clk),
        .rst                    (rst),

        `AXI4_CONNECT           (target_mmio_axi, s_mmio_axi),
        `AXI4_CONNECT           (target_dma_axi, m_dma_axi),

        .mmio_arreq_valid            (mmio_arreq_valid),
        //.mmio_arreq_id               (mmio_arreq_id),
        .mmio_arreq_addr             (mmio_arreq_addr),
        //.mmio_arreq_len              (mmio_arreq_len),
        //.mmio_arreq_size             (mmio_arreq_size),
        //.mmio_arreq_burst            (mmio_arreq_burst),

        .mmio_awreq_valid            (mmio_awreq_valid),
        //.mmio_awreq_id               (mmio_awreq_id),
        .mmio_awreq_addr             (mmio_awreq_addr),
        //.mmio_awreq_len              (mmio_awreq_len),
        //.mmio_awreq_size             (mmio_awreq_size),
        //.mmio_awreq_burst            (mmio_awreq_burst),

        .mmio_wreq_valid             (mmio_wreq_valid),
        .mmio_wreq_data              (mmio_wreq_data),
        .mmio_wreq_strb              (mmio_wreq_strb),
        //.mmio_wreq_last              (mmio_wreq_last),

        .mmio_breq_valid             (mmio_breq_valid),
        //.mmio_breq_id                (mmio_breq_id),

        .mmio_rreq_valid             (mmio_rreq_valid),
        //.mmio_rreq_id                (mmio_rreq_id),

        .mmio_rresp_data             (mmio_rresp_data),
        //.mmio_rresp_last             (mmio_rresp_last)
    );

    emulib_dmamodel_backend #(
        .MMIO_ADDR_WIDTH     (MMIO_ADDR_WIDTH),
        .MMIO_DATA_WIDTH     (MMIO_DATA_WIDTH),
        .MMIO_ID_WIDTH       (MMIO_ID_WIDTH),
        .DMA_ADDR_WIDTH      (DMA_ADDR_WIDTH),
        .DMA_DATA_WIDTH      (DMA_DATA_WIDTH),
        .DMA_ID_WIDTH        (DMA_ID_WIDTH)
    )(
        .clk                    (clk),
        .rst                    (rst),

        .mmio_arreq_valid            (mmio_arreq_valid),
        //.mmio_arreq_id               (mmio_arreq_id),
        .mmio_arreq_addr             (mmio_arreq_addr),
        //.mmio_arreq_len              (mmio_arreq_len),
        //.mmio_arreq_size             (mmio_arreq_size),
        //.mmio_arreq_burst            (mmio_arreq_burst),

        .mmio_awreq_valid            (mmio_awreq_valid),
        //.mmio_awreq_id               (mmio_awreq_id),
        .mmio_awreq_addr             (mmio_awreq_addr),
        //.mmio_awreq_len              (mmio_awreq_len),
        //.mmio_awreq_size             (mmio_awreq_size),
        //.mmio_awreq_burst            (mmio_awreq_burst),

        .mmio_wreq_valid             (mmio_wreq_valid),
        .mmio_wreq_data              (mmio_wreq_data),
        .mmio_wreq_strb              (mmio_wreq_strb),
        //.mmio_wreq_last              (mmio_wreq_last),

        .mmio_breq_valid             (mmio_breq_valid),
        //.mmio_breq_id                (mmio_breq_id),

        .mmio_rreq_valid             (mmio_rreq_valid),
        //.mmio_rreq_id                (mmio_rreq_id),

        .mmio_rresp_data             (mmio_rresp_data),
        //.mmio_rresp_last             (mmio_rresp_last)
    );

endmodule