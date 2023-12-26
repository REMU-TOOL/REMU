`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_dmamodel_frontend #(
    parameter  MMIO_ADDR_WIDTH   = 32,
    parameter  MMIO_DATA_WIDTH   = 64,
    parameter  MMIO_ID_WIDTH     = 4,
    parameter  DMA_ADDR_WIDTH   = 32,
    parameter  DMA_DATA_WIDTH   = 64,
    parameter  DMA_ID_WIDTH     = 4,
)(
    input  wire                 clk,
    input  wire                 rst,
    `AXI4LITE_SLAVE_IF          (target_mmio_axi,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH, MMIO_ID_WIDTH),
    `AXI4_MASTER_IF             (target_dma_axi,     DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH),

    //MMIO Channels to backend
    output wire                             mmio_arreq_valid,
    //output wire [MMIO_ID_WIDTH-1:0]         mmio_arreq_id,
    output wire [MMIO_ADDR_WIDTH-1:0]       mmio_arreq_addr,
    //output wire [7:0]                       mmio_arreq_len,
    //output wire [2:0]                       mmio_arreq_size,
    //output wire [1:0]                       mmio_arreq_burst,

    output wire                             mmio_awreq_valid,
    //output wire [MMIO_ID_WIDTH-1:0]         mmio_awreq_id,
    output wire [MMIO_ADDR_WIDTH-1:0]       mmio_awreq_addr,
    //output wire [7:0]                       mmio_awreq_len,
    output wire [2:0]                       mmio_awreq_size,
    //output wire [1:0]                       mmio_awreq_burst,

    output wire                             mmio_wreq_valid,
    output wire [MMIO_DATA_WIDTH-1:0]       mmio_wreq_data,
    output wire [MMIO_DATA_WIDTH/8-1:0]     mmio_wreq_strb,
   // output wire                             mmio_wreq_last,

    output wire                             mmio_breq_valid,
    //output wire [MMIO_ID_WIDTH-1:0]         mmio_breq_id,

    output wire                             mmio_rreq_valid,
    //output wire [MMIO_ID_WIDTH-1:0]         mmio_rreq_id,

    input  wire [MMIO_DATA_WIDTH-1:0]       mmio_rresp_data,
    //input  wire                             mmio_rresp_last,
    //TODO: DMA Channels to backend
);

//AW Channel Payload
//assign mmio_awreq_id     = target_mmio_axi_awid;
assign mmio_awreq_addr   = target_mmio_axi_awaddr;
//assign mmio_awreq_len    = target_mmio_axi_awlen;
//assign mmio_awreq_size   = target_mmio_axi_awsize;
//assign mmio_awreq_burst  = target_mmio_axi_awburst;

//W Channel Payload
assign mmio_wreq_data = target_mmio_axi_wdata;
//assign mmio_wreq_last = target_mmio_axi_wlast;
assign mmio_wreq_strb = target_mmio_axi_wstrb;

//AR Channel Payload
//assign mmio_arreq_id     = target_mmio_axi_arid;
assign mmio_arreq_addr   = target_mmio_axi_araddr;
//assign mmio_arreq_len    = target_mmio_axi_arlen;
//assign mmio_arreq_size   = target_mmio_axi_arsize;
//assign mmio_arreq_burst  = target_mmio_axi_arburst;

//TODO MMIO Latency Pipe
latency_pipe u_mmio_latency_pipe #(
    .ADDR_WIDTH(MMIO_ADDR_WIDTH),
    .DATA_WIDTH(MMIO_DATA_WIDTH),
    .MAX_R_INFLIGHT(1),
    .MAX_W_INFLIGHT(1)
)(
    .clk        (clk    ), 
    .rst        (rst    ), 
    .arvalid    (target_mmio_axi_arvalid), 
    .arready    (target_mmio_axi_arready), 
    .arid       (target_mmio_axi_arid   ), 
    .araddr     (target_mmio_axi_araddr ), 
    .arlen      (target_mmio_axi_arlen  ), 
    .arsize     (target_mmio_axi_arsize ), 
    .arburst    (target_mmio_axi_arburst), 
    .awvalid    (target_mmio_axi_awvalid), 
    .awready    (target_mmio_axi_awready), 
    .awid       (target_mmio_axi_awid   ), 
    .awaddr     (target_mmio_axi_awaddr ), 
    .awlen      (target_mmio_axi_awlen  ), 
    .awsize     (target_mmio_axi_awsize ), 
    .awburst    (target_mmio_axi_awburst), 
    .wvalid     (target_mmio_axi_wvalid ), 
    .wready     (target_mmio_axi_wready ), 
    .wlast      (target_mmio_axi_wlast  ), 
    .bvalid     (target_mmio_axi_bvalid ), 
    .bready     (target_mmio_axi_bready ), 
    .bid        (target_mmio_axi_bid    ), 
    .rvalid     (target_mmio_axi_rvalid ), 
    .rready     (target_mmio_axi_rready ), 
    .rid        (target_mmio_axi_rid    )
);

//TODO Handle DMA Requests

endmodule