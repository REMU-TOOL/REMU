`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_dmamodel_backend #(
    parameter  MMIO_ADDR_WIDTH   = 32,
    parameter  MMIO_DATA_WIDTH   = 32,
    parameter  DMA_ADDR_WIDTH    = 32,
    parameter  DMA_DATA_WIDTH    = 64,
    parameter  DMA_ID_WIDTH      = 4,
    parameter  MAX_R_INFLIGHT    = 1,
    parameter  MAX_W_INFLIGHT    = 1
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
    input wire [MMIO_ADDR_WIDTH-1:0]       mmio_arreq_addr,
    input wire [2:0]                       mmio_arreq_prot,

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
    input wire [MMIO_ADDR_WIDTH-1:0]       mmio_awreq_addr,
    input wire [2:0]                       mmio_awreq_prot,

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
    output wire [1:0]                       mmio_bresp_resp,

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
    output  wire [1:0]                       mmio_rresp_resp,

    (* __emu_axi_name = "host_mmio_axi" *)
    (* __emu_axi_type = "axi4-dma" *)
    `AXI4LITE_MASTER_IF                     (host_mmio_axi,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH),

    (* __emu_axi_name = "host_dma_axi" *)
    (* __emu_axi_type = "axi4-dma" *)
    `AXI4_SLAVE_IF                          (host_dma_axi,     DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH),

    //DMA Channel
    (* __emu_channel_name = "dma_port" *)
    (* __emu_channel_direction = "out" *)
    (* __emu_channel_payload = "dma_port_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_dma_port_valid" *)
    (* __emu_channel_ready = "tk_dma_port_ready" *)

    output wire                              tk_dma_port_valid,
    input  wire                              tk_dma_port_ready,

    output  wire                             dma_port_arvalid,
    input   wire                             dma_port_arready,
    output  wire [DMA_ADDR_WIDTH-1:0]        dma_port_araddr,
    output  wire [DMA_ID_WIDTH-1:0]          dma_port_arid,
    output  wire [7:0]                       dma_port_arlen,
    output  wire [2:0]                       dma_port_arsize,
    output  wire [1:0]                       dma_port_arburst,
    output  wire [2:0]                       dma_port_arprot,

    output  wire                             dma_port_awvalid,
    input   wire                             dma_port_awready,
    output  wire [DMA_ADDR_WIDTH-1:0]        dma_port_awaddr,
    output  wire [DMA_ID_WIDTH-1:0]          dma_port_awid,
    output  wire [7:0]                       dma_port_awlen,
    output  wire [2:0]                       dma_port_awsize,
    output  wire [1:0]                       dma_port_awburst,
    output  wire [2:0]                       dma_port_awprot,

    output  wire                             dma_port_wvalid,
    input   wire                             dma_port_wready,
    output  wire [DMA_DATA_WIDTH-1:0]        dma_port_wdata,
    output  wire [DMA_DATA_WIDTH/8-1:0]      dma_port_wstrb,
    output  wire                             dma_port_wlast,

    input   wire                             dma_port_rvalid,
    output  wire                             dma_port_rready,
    input   wire [DMA_DATA_WIDTH-1:0]        dma_port_rdata,  
    input   wire [DMA_ID_WIDTH-1:0]          dma_port_rid,
    input   wire                             dma_port_rlast,
    input   wire [1:0]                       dma_port_rresp,

    input   wire                             dma_port_bvalid,
    output  wire                             dma_port_bready,
    input  wire [DMA_ID_WIDTH-1:0]           dma_port_bid,
    input  wire [1:0]                        dma_port_bresp,


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
assign host_mmio_axi_arprot = mmio_arreq_prot;

assign host_mmio_axi_awaddr = mmio_awreq_addr;
assign host_mmio_axi_awvalid = mmio_awreq_valid && tk_mmio_awreq_valid && !scan_mode;
assign tk_mmio_awreq_ready = host_mmio_axi_awready || !mmio_awreq_valid;
assign host_mmio_axi_awprot = mmio_awreq_prot;

assign host_mmio_axi_wdata = mmio_wreq_data;
assign host_mmio_axi_wvalid = mmio_wreq_valid && tk_mmio_wreq_valid;
assign host_mmio_axi_wstrb  = mmio_wreq_strb;
assign tk_mmio_wreq_ready = host_mmio_axi_wready || !mmio_wreq_valid;

assign mmio_bresp_resp = host_mmio_axi_bresp;

assign host_mmio_axi_rready = 1;
assign host_mmio_axi_bready = 1;

assign mmio_rresp_data = pre_resp_rdata;
assign mmio_rresp_resp = pre_resp_rresp;


wire r_whitehole = !waiting_backend_rresp;
wire resp_data_ready = waiting_backend_rresp && !waiting_host_rdata;

assign tk_mmio_rreq_ready = tk_mmio_rresp_ready && (r_whitehole || resp_data_ready);
assign tk_mmio_rresp_valid = tk_mmio_rreq_valid && (r_whitehole || resp_data_ready);


reg [MMIO_DATA_WIDTH-1:0] pre_resp_rdata;
reg [1:0] pre_resp_rresp;
reg waiting_host_rdata = 0;
always @(posedge mdl_clk) begin
    if(mdl_rst) begin
        pre_resp_rdata <= 0;
        pre_resp_rresp <= 0;
    end
    else if(host_mmio_axi_rready && host_mmio_axi_rvalid && !reset_pending)begin
        pre_resp_rdata <= host_mmio_axi_rdata;
        pre_resp_rresp <= host_mmio_axi_rresp;
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

/* ================================ DMA QUEUE ====================================*/

    localparam  A_PAYLOAD_LEN   = `AXI4_CUSTOM_A_PAYLOAD_LEN(DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH);
    localparam  W_PAYLOAD_LEN   = `AXI4_CUSTOM_W_PAYLOAD_LEN(DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH);
    localparam  B_PAYLOAD_LEN   = `AXI4_CUSTOM_B_PAYLOAD_LEN(DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH);
    localparam  R_PAYLOAD_LEN   = `AXI4_CUSTOM_R_PAYLOAD_LEN(DMA_ADDR_WIDTH, DMA_DATA_WIDTH, DMA_ID_WIDTH);

    localparam  A_ISSUE_Q_DEPTH = MAX_R_INFLIGHT + MAX_W_INFLIGHT;
    localparam  W_ISSUE_Q_DEPTH = 256 * MAX_W_INFLIGHT;
    localparam  R_ISSUE_Q_DEPTH = 256 * MAX_R_INFLIGHT;
    localparam  B_ISSUE_Q_DEPTH = MAX_W_INFLIGHT;

    assign tk_dma_port_valid = 1'b1;

    //AR/AW FIFO
    wire fifo_rst = soft_rst || mdl_rst;
    emulib_ready_valid_fifo #(
        .WIDTH      (A_PAYLOAD_LEN),
        .DEPTH      (A_ISSUE_Q_DEPTH)
    ) ar_issue_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (host_dma_axi_arvalid),
        .iready     (host_dma_axi_arready),
        .idata      ({host_dma_axi_araddr,host_dma_axi_arid,host_dma_axi_arlen,host_dma_axi_arsize,host_dma_axi_arburst,host_dma_axi_arprot}),
        .ovalid     (dma_port_arvalid),
        .oready     (dma_port_arready),
        .odata      ({dma_port_araddr,dma_port_arid,dma_port_arlen,dma_port_arsize,dma_port_arburst,dma_port_arprot})
    );

    emulib_ready_valid_fifo #(
        .WIDTH      (A_PAYLOAD_LEN),
        .DEPTH      (A_ISSUE_Q_DEPTH)
    ) aw_issue_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (host_dma_axi_awvalid),
        .iready     (host_dma_axi_awready),
        .idata      ({host_dma_axi_awaddr,host_dma_axi_awid,host_dma_axi_awlen,host_dma_axi_awsize,host_dma_axi_awburst,host_dma_axi_awprot}),
        .ovalid     (dma_port_awvalid),
        .oready     (dma_port_awready),
        .odata      ({dma_port_awaddr,dma_port_awid,dma_port_awlen,dma_port_awsize,dma_port_awburst,dma_port_awprot})
    );

    //W FIFO
    emulib_ready_valid_fifo #(
        .WIDTH      (W_PAYLOAD_LEN),
        .DEPTH      (W_ISSUE_Q_DEPTH)
    ) w_issue_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (host_dma_axi_wvalid),
        .iready     (host_dma_axi_wready),
        .idata      (`AXI4_CUSTOM_W_PAYLOAD(host_dma_axi)),
        .ovalid     (dma_port_wvalid),
        .oready     (dma_port_wready),
        .odata      (`AXI4_CUSTOM_W_PAYLOAD(dma_port))
    );
    //R FIFO
    emulib_ready_valid_fifo #(
        .WIDTH      (R_PAYLOAD_LEN),
        .DEPTH      (R_ISSUE_Q_DEPTH)
    ) r_issue_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (dma_port_rvalid),
        .iready     (dma_port_rready),
        .idata      (`AXI4_CUSTOM_R_PAYLOAD(dma_port)),
        .ovalid     (host_dma_axi_rvalid),
        .oready     (host_dma_axi_rready),
        .odata      (`AXI4_CUSTOM_R_PAYLOAD(host_dma_axi))
    );
    //B FIFO
    emulib_ready_valid_fifo #(
        .WIDTH      (B_PAYLOAD_LEN),
        .DEPTH      (B_ISSUE_Q_DEPTH)
    ) b_issue_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (dma_port_bvalid),
        .iready     (dma_port_bready),
        .idata      (`AXI4_CUSTOM_B_PAYLOAD(dma_port)),
        .ovalid     (host_dma_axi_bvalid),
        .oready     (host_dma_axi_bready),
        .odata      (`AXI4_CUSTOM_B_PAYLOAD(host_dma_axi))
    );
    assign host_dma_axi_bresp = 2'b00;
    assign host_dma_axi_rresp = 2'b00;

endmodule