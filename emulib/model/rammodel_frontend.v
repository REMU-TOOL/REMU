`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_frontend #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8,
    parameter   TIMING_TYPE     = "fixed"
)(

    input  wire                     clk,
    input  wire                     rst,

    `AXI4_SLAVE_IF                  (target_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                     arreq_valid,
    output wire [ID_WIDTH-1:0]      arreq_id,
    output wire [ADDR_WIDTH-1:0]    arreq_addr,
    output wire [7:0]               arreq_len,
    output wire [2:0]               arreq_size,
    output wire [1:0]               arreq_burst,

    output wire                     awreq_valid,
    output wire [ID_WIDTH-1:0]      awreq_id,
    output wire [ADDR_WIDTH-1:0]    awreq_addr,
    output wire [7:0]               awreq_len,
    output wire [2:0]               awreq_size,
    output wire [1:0]               awreq_burst,

    output wire                     wreq_valid,
    output wire [DATA_WIDTH-1:0]    wreq_data,
    output wire [DATA_WIDTH/8-1:0]  wreq_strb,
    output wire                     wreq_last,

    output wire                     breq_valid,
    output wire [ID_WIDTH-1:0]      breq_id,

    output wire                     rreq_valid,
    output wire [ID_WIDTH-1:0]      rreq_id,

    input  wire [DATA_WIDTH-1:0]    rresp_data,
    input  wire                     rresp_last

);

    `AXI4_WIRE(tracker, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    wire timing_model_awvalid, timing_model_awready;
    wire timing_model_wvalid,  timing_model_wready;
    wire timing_model_arvalid, timing_model_arready;
    wire timing_model_bvalid,  timing_model_bready;
    wire timing_model_rvalid,  timing_model_rready;

    // Fork target AW, W, AR to tracker & timing model & backend

    emulib_ready_valid_fork #(.BRANCHES(3)) fork_aw (
        .i_valid        (target_axi_awvalid),
        .i_ready        (target_axi_awready),
        .o_valid        ({awreq_valid, timing_model_awvalid, tracker_awvalid}),
        .o_ready        ({1'b1, timing_model_awready, tracker_awready})
    );

    assign `AXI4_AW_PAYLOAD(tracker) = `AXI4_AW_PAYLOAD(target_axi);

    assign awreq_id     = target_axi_awid;
    assign awreq_addr   = target_axi_awaddr;
    assign awreq_len    = target_axi_awlen;
    assign awreq_size   = target_axi_awsize;
    assign awreq_burst  = target_axi_awburst;

    emulib_ready_valid_fork #(.BRANCHES(3)) fork_w (
        .i_valid        (target_axi_wvalid),
        .i_ready        (target_axi_wready),
        .o_valid        ({wreq_valid, timing_model_wvalid, tracker_wvalid}),
        .o_ready        ({1'b1, timing_model_wready, tracker_wready})
    );

    assign `AXI4_W_PAYLOAD(tracker) = `AXI4_W_PAYLOAD(target_axi);

    assign wreq_data    = target_axi_wdata;
    assign wreq_strb    = target_axi_wstrb;
    assign wreq_last    = target_axi_wlast;

    emulib_ready_valid_fork #(.BRANCHES(3)) fork_ar (
        .i_valid        (target_axi_arvalid),
        .i_ready        (target_axi_arready),
        .o_valid        ({arreq_valid, timing_model_arvalid, tracker_arvalid}),
        .o_ready        ({1'b1, timing_model_arready, tracker_arready})
    );

    assign `AXI4_AR_PAYLOAD(tracker) = `AXI4_AR_PAYLOAD(target_axi);

    assign arreq_id     = target_axi_arid;
    assign arreq_addr   = target_axi_araddr;
    assign arreq_len    = target_axi_arlen;
    assign arreq_size   = target_axi_arsize;
    assign arreq_burst  = target_axi_arburst;

    // Tracker

    emulib_rammodel_tracker #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .MAX_R_INFLIGHT (MAX_R_INFLIGHT),
        .MAX_W_INFLIGHT (MAX_W_INFLIGHT)
    ) tracker (
        .clk            (clk),
        .rst            (rst),
        `AXI4_CONNECT   (axi, tracker)
    );

    // Timing model

    emulib_rammodel_timing_model #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .MAX_R_INFLIGHT (MAX_R_INFLIGHT),
        .MAX_W_INFLIGHT (MAX_W_INFLIGHT),
        .TIMING_TYPE    ("fixed")
    )
    timing_model (
        .clk        (clk),
        .rst        (rst),
        .arvalid    (timing_model_arvalid),
        .arready    (timing_model_arready),
        .arid       (target_axi_arid),
        .araddr     (target_axi_araddr),
        .arlen      (target_axi_arlen),
        .arsize     (target_axi_arsize),
        .arburst    (target_axi_arburst),
        .awvalid    (timing_model_awvalid),
        .awready    (timing_model_awready),
        .awid       (target_axi_awid),
        .awaddr     (target_axi_awaddr),
        .awlen      (target_axi_awlen),
        .awsize     (target_axi_awsize),
        .awburst    (target_axi_awburst),
        .wvalid     (timing_model_wvalid),
        .wready     (timing_model_wready),
        .wlast      (target_axi_wlast),
        .bvalid     (timing_model_bvalid),
        .bready     (timing_model_bready),
        .bid        (target_axi_bid),
        .rvalid     (timing_model_rvalid),
        .rready     (timing_model_rready),
        .rid        (target_axi_rid)
    );

    assign breq_valid       = timing_model_bvalid && timing_model_bready;
    assign breq_id          = target_axi_bid;
    assign rreq_valid       = timing_model_rvalid && timing_model_rready;
    assign rreq_id          = target_axi_rid;

    assign target_axi_bresp = 2'b00;
    assign target_axi_rdata = rresp_data;
    assign target_axi_rlast = rresp_last;
    assign target_axi_rresp = 2'b00;

    assign target_axi_bvalid    = timing_model_bvalid;
    assign timing_model_bready  = target_axi_bready;

    assign target_axi_rvalid    = timing_model_rvalid;
    assign timing_model_rready  = target_axi_rready;

    // Mirror B & R to tracker

    assign tracker_bvalid       = target_axi_bvalid;
    assign tracker_bready       = target_axi_bready;

    assign tracker_rvalid       = target_axi_rvalid;
    assign tracker_rready       = target_axi_rready;

    assign `AXI4_B_PAYLOAD(tracker) = `AXI4_B_PAYLOAD(target_axi);
    assign `AXI4_R_PAYLOAD(tracker) = `AXI4_R_PAYLOAD(target_axi);

endmodule
