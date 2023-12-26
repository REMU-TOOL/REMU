`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_dmamodel_backend #(
    parameter  MMIO_ADDR_WIDTH   = 32,
    parameter  MMIO_DATA_WIDTH   = 64,
    parameter  MMIO_ID_WIDTH     = 4,
    parameter  DMA_ADDR_WIDTH   = 32,
    parameter  DMA_DATA_WIDTH   = 64,
    parameter  DMA_ID_WIDTH     = 4,
)(
    (* __emu_common_port = "mdl_clk" *)
    input  wire                             mdl_clk,
    (* __emu_common_port = "mdl_rst" *)
    input  wire                             mdl_rst,
    input  wire                             clk,

    // MMIO Reset Channel

    (* __emu_channel_name = "dma_rst"*)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "rst" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_dma_rst_valid" *)
    (* __emu_channel_ready = "tk_dma_rst_ready" *)

    input  wire                            tk_dma_rst_valid,
    output wire                            tk_dma_rst_ready,
    input  wire                            rst,

    // MMIO ARReq Channel

    (* __emu_channel_name = "mmio_arreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "mmio_arreq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_mmio_arreq_valid" *)
    (* __emu_channel_ready = "tk_mmio_arreq_ready" *)

    input  wire                            tk_mmio_arreq_valid,
    output wire                            tk_mmio_arreq_ready,

    input wire                             mmio_arreq_valid,
    //input wire [MMIO_ID_WIDTH-1:0]         mmio_arreq_id,
    input wire [MMIO_ADDR_WIDTH-1:0]       mmio_arreq_addr,
    //input wire [7:0]                       mmio_arreq_len,
    //input wire [2:0]                       mmio_arreq_size,
    //input wire [1:0]                       mmio_arreq_burst,

    // MMIO AWReq Channel

    (* __emu_channel_name = "mmio_awreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "mmio_awreq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_mmio_awreq_valid" *)
    (* __emu_channel_ready = "tk_mmio_awreq_ready" *)

    input  wire                            tk_mmio_awreq_valid,
    output wire                            tk_mmio_awreq_ready,

    input wire                             mmio_awreq_valid,
    //input wire [MMIO_ID_WIDTH-1:0]         mmio_awreq_id,
    input wire [MMIO_ADDR_WIDTH-1:0]       mmio_awreq_addr,
    //input wire [7:0]                       mmio_awreq_len,
    //input wire [2:0]                       mmio_awreq_size,
    //input wire [1:0]                       mmio_awreq_burst,

    // MMIO WReq Channel

    (* __emu_channel_name = "mmio_wreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "mmio_wreq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_mmio_wreq_valid" *)
    (* __emu_channel_ready = "tk_mmio_wreq_ready" *)

    input  wire                            tk_mmio_wreq_valid,
    output wire                            tk_mmio_wreq_ready,

    input wire                             mmio_wreq_valid,
    input wire [MMIO_DATA_WIDTH-1:0]       mmio_wreq_data,
    input wire [MMIO_DATA_WIDTH/8-1:0]     mmio_wreq_strb,
    //input wire                             mmio_wreq_last,
    // MMIO BReq Channel
    (* __emu_channel_name = "mmio_breq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "mmio_breq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_mmio_breq_valid" *)
    (* __emu_channel_ready = "tk_mmio_breq_ready" *)

    input  wire                            tk_mmio_breq_valid,
    output wire                            tk_mmio_breq_ready,

    input wire                             mmio_breq_valid,
    //input wire [MMIO_ID_WIDTH-1:0]         mmio_breq_id,

    // MMIO RReq Channel
    (* __emu_channel_name = "mmio_rreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "mmio_rreq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_mmio_rreq_valid" *)
    (* __emu_channel_ready = "tk_mmio_rreq_ready" *)

    input  wire                            tk_mmio_rreq_valid,
    output wire                            tk_mmio_rreq_ready,

    input wire                             mmio_rreq_valid,
    //input wire [MMIO_ID_WIDTH-1:0]         mmio_rreq_id,

    // MMIO BResp Channel

    (* __emu_channel_name = "mmio_bresp" *)
    (* __emu_channel_direction = "out" *)
    (* __emu_channel_depends_on = "mmio_breq" *)
    (* __emu_channel_payload = "mmio_bresp_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_mmio_bresp_valid" *)
    (* __emu_channel_ready = "tk_mmio_bresp_ready" *)

    output wire                             tk_mmio_bresp_valid,
    input  wire                             tk_mmio_bresp_ready,

    // MMIO RResp Channel

    (* __emu_channel_name = "mmio_rresp" *)
    (* __emu_channel_direction = "out" *)
    (* __emu_channel_depends_on = "mmio_rreq" *)
    (* __emu_channel_payload = "mmio_rresp_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_mmio_rresp_valid" *)
    (* __emu_channel_ready = "tk_mmio_rresp_ready" *)

    output wire                              tk_mmio_rresp_valid,
    input  wire                              tk_mmio_rresp_ready,

    output  wire [MMIO_DATA_WIDTH-1:0]       mmio_rresp_data,
    //output  wire                             mmio_rresp_last,

    (* __emu_axi_name = "host_mmio_axi" *)
    (* __emu_axi_type = "axi4lite" *)
    `AXI4LITE_MASTER_IF                     (host_mmio_axi,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH, MMIO_ID_WIDTH),

    (* __emu_axi_name = "host_dma_axi" *)
    (* __emu_axi_type = "axi4" *)
    `AXI4_SLAVE_IF                          (host_dma_axi,     DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH),

    //TODO: DMA Channels 

    (* __emu_common_port = "run_mode" *)
    input  wire                             run_mode,
    (* __emu_common_port = "scan_mode" *)
    input  wire                             scan_mode,
    (* __emu_common_port = "idle" *)
    output wire                             idle
);

(* __emu_no_scanchain *)
reset_token_handler resetter (
    .mdl_clk        (mdl_clk),
    .mdl_rst        (mdl_rst),
    .tk_rst_valid   (tk_dma_rst_valid),
    .tk_rst_ready   (tk_dma_rst_ready),
    .tk_rst         (rst),
    .allow_rst      (idle),
    .rst_out        (soft_rst)
);
wire soft_rst;

assign host_mmio_axi_araddr = mmio_arreq_addr;
assign host_mmio_axi_arvalid = mmio_arreq_valid && tk_mmio_arreq_valid && !scan_mode;
assign tk_mmio_arreq_ready = host_mmio_axi_arready || !mmio_arreq_valid;

assign host_mmio_axi_awaddr = mmio_awreq_addr;
assign host_mmio_axi_awvalid = mmio_awreq_valid && tk_mmio_awreq_valid && !scan_mode;
assign tk_mmio_awreq_ready = host_mmio_axi_awready || !mmio_awreq_valid;

assign host_mmio_axi_wdata = mmio_wreq_data;
assign host_mmio_axi_wvalid = mmio_wreq_valid && tk_mmio_wreq_valid;
assign tk_mmio_wreq_ready = host_mmio_axi_wready || !tk_mmio_wreq_ready;


assign host_mmio_axi_rready = 1;
assign host_mmio_axi_bready = 1;

assign mmio_rresp_data = pre_resp_rdata;

wire r_whitehole = !waiting_backend_rresp;
wire resp_data_ready = waiting_backend_rresp && !waiting_host_rdata;

assign tk_mmio_rreq_ready = tk_mmio_rresp_ready && (r_whitehole || resp_data_ready);
assign tk_mmio_rresp_valid = tk_mmio_rreq_valid && (r_whitehole || resp_data_ready);


reg [MMIO_DATA_WIDTH-1:0] pre_resp_rdata;
reg waiting_host_rdata = 0;
always @(posedge mdl_clk) begin
    if(mdl_rst) begin
        pre_resp_rdata <= 0;
    end
    else if(host_mmio_axi_rready && host_mmio_axi_rvalid && !reset_pending)begin
        pre_resp_rdata <= host_mmio_axi_rdata;
        waiting_host_rdata <= 0;
    end
    else if(host_mmio_axi_arready && host_mmio_axi_arvalid)
        waiting_host_rdata <= 1;
end

reg waiting_backend_rresp = 0;
always @(posedge mdl_clk) begin
    if(tk_mmio_rreq_valid && mmio_rreq_valid && !reset_pending)begin
        waiting_backend_rresp <= 1;
    end
    else if (tk_mmio_rresp_ready && tk_mmio_rresp_valid)
        waiting_backend_rresp <= 0;
end

wire b_whitehole = !waiting_backend_bresp;
wire bresp_ready = waiting_backend_bresp && !waiting_host_bresp;

assign tk_mmio_breq_ready = tk_mmio_bresp_ready && (b_whitehole || bresp_ready);
assign tk_mmio_bresp_valid = tk_mmio_breq_valid && (b_whitehole || bresp_ready);

reg waiting_host_bresp = 0;
always @(posedge mdl_clk) begin
    if(host_mmio_axi_bready && host_mmio_axi_bvalid && !reset_pending)begin
        waiting_host_bresp <= 0;
    end
    else if(host_mmio_axi_wready && host_mmio_axi_wvalid)
        waiting_host_bresp <= 1;
end

reg waiting_backend_bresp = 0;
always @(posedge mdl_clk) begin
    if(tk_mmio_breq_valid && mmio_breq_valid && !reset_pending)begin
        waiting_backend_bresp <= 1;
    end
    else if (tk_mmio_bresp_ready && tk_mmio_bresp_valid)
        waiting_backend_bresp <= 0;
end

wire reset_pending = tk_dma_rst_valid && rst;

assign idle = !host_mmio_axi_arvalid && !host_mmio_axi_awvalid && r_whitehole && b_whitehole;

endmodule