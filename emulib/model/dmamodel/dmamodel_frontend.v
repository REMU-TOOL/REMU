`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_dmamodel_frontend #(
    parameter  MMIO_ADDR_WIDTH   = 32,
    parameter  MMIO_DATA_WIDTH   = 32,
    parameter  DMA_ADDR_WIDTH   = 32,
    parameter  DMA_DATA_WIDTH   = 64,
    parameter  DMA_ID_WIDTH     = 4
)(
    input  wire                 clk,
    input  wire                 rst,
    `AXI4LITE_SLAVE_IF          (target_mmio_axi,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH),
    `AXI4_MASTER_IF             (target_dma_axi,     DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH),

    //MMIO Channels to backend
    output wire                             mmio_arreq_valid,
    output wire [MMIO_ADDR_WIDTH-1:0]       mmio_arreq_addr,
    output wire [2:0]                       mmio_arreq_size,

    output wire                             mmio_awreq_valid,
    output wire [MMIO_ADDR_WIDTH-1:0]       mmio_awreq_addr,
    output wire [2:0]                       mmio_awreq_size,

    output wire                             mmio_wreq_valid,
    output wire [MMIO_DATA_WIDTH-1:0]       mmio_wreq_data,
    output wire [MMIO_DATA_WIDTH/8-1:0]     mmio_wreq_strb,

    output wire                             mmio_breq_valid,
    output wire                             mmio_rreq_valid,
    input  wire [MMIO_DATA_WIDTH-1:0]       mmio_rresp_data,

    //DMA Channels to backend
    input  wire                             dma_arreq_valid,
    output wire                             dma_arreq_ready,
    input  wire [DMA_ADDR_WIDTH-1:0]        dma_arreq_addr,
    input  wire [DMA_ID_WIDTH-1:0]          dma_arreq_id,
    input  wire [7:0]                       dma_arreq_len,
    input  wire [2:0]                       dma_arreq_size,
    input  wire [1:0]                       dma_arreq_burst,

    input  wire                             dma_awreq_valid,
    output wire                             dma_awreq_ready,
    input  wire [DMA_ADDR_WIDTH-1:0]        dma_awreq_addr,
    input  wire [DMA_ID_WIDTH-1:0]          dma_awreq_id,
    input  wire [7:0]                       dma_awreq_len,
    input  wire [2:0]                       dma_awreq_size,
    input  wire [1:0]                       dma_awreq_burst,

    input  wire                             dma_wreq_valid,
    output wire                             dma_wreq_ready,
    input  wire [DMA_DATA_WIDTH-1:0]        dma_wreq_data,
    input  wire [DMA_DATA_WIDTH/8-1:0]      dma_wreq_strb,
    input  wire                             dma_wreq_last,

    output wire                             dma_rreq_valid,
    input  wire                             dma_rreq_ready,
    output wire [DMA_DATA_WIDTH-1:0]        dma_rreq_data,  
    output wire [DMA_ID_WIDTH-1:0]          dma_rreq_id,
    output wire                             dma_rreq_last,

    output wire                             dma_breq_valid,
    input  wire                             dma_breq_ready,
    output  wire [DMA_ID_WIDTH-1:0]          dma_breq_id,
    output  wire [1:0]                       dma_breq_bresp
);
/* =========================== MMIO PORT =============================*/
//AW Channel Payload
assign mmio_awreq_addr   = target_mmio_axi_awaddr;

//W Channel Payload
assign mmio_wreq_data = target_mmio_axi_wdata;
assign mmio_wreq_strb = target_mmio_axi_wstrb;

//AR Channel Payload
assign mmio_arreq_addr   = target_mmio_axi_araddr;

//TODO MMIO Latency Pipe
latency_pipe #(
    .ADDR_WIDTH(MMIO_ADDR_WIDTH),
    .MAX_R_INFLIGHT(1),
    .MAX_W_INFLIGHT(1)
) u_mmio_latency_pipe(
    .clk        (clk    ), 
    .rst        (rst    ), 
    .arvalid    (target_mmio_axi_arvalid), 
    .arready    (target_mmio_axi_arready), 
    .arid       (0   ), 
    .araddr     (target_mmio_axi_araddr ), 
    .arlen      (0  ), 
    .arsize     (3'b011), 
    .arburst    (2'b01), 
    .awvalid    (target_mmio_axi_awvalid), 
    .awready    (target_mmio_axi_awready), 
    .awid       (0   ), 
    .awaddr     (target_mmio_axi_awaddr ), 
    .awlen      (0  ), 
    .awsize     (3'b011), 
    .awburst    (2'b01), 
    .wvalid     (target_mmio_axi_wvalid ), 
    .wready     (target_mmio_axi_wready ), 
    .wlast      ( target_mmio_axi_wvalid && target_mmio_axi_wready ), 
    .bvalid     (target_mmio_axi_bvalid ), 
    .bready     (target_mmio_axi_bready ), 
    .bid        (   ), 
    .rvalid     (target_mmio_axi_rvalid ), 
    .rready     (target_mmio_axi_rready ), 
    .rid        (   )
);

/* =========================== DMA PORT =============================*/

//AW Channel Payload
assign target_dma_axi_awid     = dma_awreq_id;
assign target_dma_axi_awaddr   = dma_awreq_addr;
assign target_dma_axi_awlen    = dma_awreq_len;
assign target_dma_axi_awsize   = dma_awreq_size;
assign target_dma_axi_awburst  = dma_awreq_burst;
assign target_dma_axi_awvalid  = dma_awreq_valid;
assign dma_awreq_ready         = target_dma_axi_awready;

//W Channel Payload
assign target_dma_axi_wdata    = dma_wreq_data;
assign target_dma_axi_wlast    = dma_wreq_last;
assign target_dma_axi_wstrb    = dma_wreq_strb;
assign target_dma_axi_wvalid   = dma_wreq_valid;
assign dma_wreq_ready          = target_dma_axi_wready;

//AR Channel Payload
assign target_dma_axi_arid     = dma_arreq_id;
assign target_dma_axi_araddr   = dma_arreq_addr;
assign target_dma_axi_arlen    = dma_arreq_len;
assign target_dma_axi_arsize   = dma_arreq_size;
assign target_dma_axi_arburst  = dma_arreq_burst;
assign target_dma_axi_arvalid  = dma_arreq_valid;
assign dma_arreq_ready         = target_dma_axi_arready;

//R Channel Payload
assign dma_rreq_data = target_dma_axi_rdata;
assign dma_rreq_id = target_dma_axi_rid;
assign dma_rreq_last = target_dma_axi_rlast;
assign dma_rreq_valid = target_dma_axi_rvalid;
assign target_dma_axi_rready = dma_rreq_ready;

//B Channel Payload
assign dma_breq_id = target_dma_axi_bid;
assign dma_breq_bresp = target_dma_axi_bresp;
assign dma_breq_valid = target_dma_axi_bvalid;
assign target_dma_axi_bready = dma_breq_ready;

endmodule