`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_frontend #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MAX_INFLIGHT    = 8,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input  wire                     clk,
    input  wire                     rst,

    `AXI4_SLAVE_IF                  (target_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                     areq_valid,
    output wire                     areq_write,
    output wire [ID_WIDTH-1:0]      areq_id,
    output wire [ADDR_WIDTH-1:0]    areq_addr,
    output wire [7:0]               areq_len,
    output wire [2:0]               areq_size,
    output wire [1:0]               areq_burst,

    output wire                     wreq_valid,
    output wire [DATA_WIDTH-1:0]    wreq_data,
    output wire [DATA_WIDTH/8-1:0]  wreq_strb,
    output wire                     wreq_last,

    output wire                     breq_valid,
    output wire [ID_WIDTH-1:0]      breq_id,

    output wire                     rreq_valid,
    output wire [ID_WIDTH-1:0]      rreq_id,
    input  wire [DATA_WIDTH-1:0]    rreq_data,
    input  wire                     rreq_last

);

    `AXI4_WIRE(tracker, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    wire timing_model_awvalid, timing_model_awready;
    wire timing_model_wvalid, timing_model_wready;
    wire timing_model_arvalid, timing_model_arready;
    wire timing_model_bvalid, timing_model_bready;
    wire timing_model_rvalid, timing_model_rready;

    // Fork target AW, W, AR to tracker & timing model

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_aw (
        .s_valid        (target_axi_awvalid),
        .s_ready        (target_axi_awready),
        .m_valid        ({timing_model_awvalid, tracker_awvalid}),
        .m_ready        ({timing_model_awready, tracker_awready})
    );

    assign `AXI4_AW_PAYLOAD(tracker) = `AXI4_AW_PAYLOAD(target_axi);

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_w (
        .s_valid        (target_axi_wvalid),
        .s_ready        (target_axi_wready),
        .m_valid        ({timing_model_wvalid, tracker_wvalid}),
        .m_ready        ({timing_model_wready, tracker_wready})
    );

    assign `AXI4_W_PAYLOAD(tracker) = `AXI4_W_PAYLOAD(target_axi);

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_ar (
        .s_valid        (target_axi_arvalid),
        .s_ready        (target_axi_arready),
        .m_valid        ({timing_model_arvalid, tracker_arvalid}),
        .m_ready        ({timing_model_arready, tracker_arready})
    );

    assign `AXI4_AR_PAYLOAD(tracker) = `AXI4_AR_PAYLOAD(target_axi);

    // Tracker

    emulib_rammodel_tracker #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .MAX_INFLIGHT   (MAX_INFLIGHT)
    ) tracker (
        .clk            (clk),
        .rst            (rst),
        `AXI4_CONNECT   (axi, tracker),
        .areq_valid     (areq_valid),
        .areq_write     (areq_write),
        .areq_id        (areq_id),
        .areq_addr      (areq_addr),
        .areq_len       (areq_len),
        .areq_size      (areq_size),
        .areq_burst     (areq_burst),
        .wreq_valid     (wreq_valid),
        .wreq_data      (wreq_data),
        .wreq_strb      (wreq_strb),
        .wreq_last      (wreq_last)
    );

    // Timing model

    emulib_rammodel_tm_fixed #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .R_DELAY    (R_DELAY),
        .W_DELAY    (W_DELAY)
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
    assign target_axi_rdata = rreq_data;
    assign target_axi_rlast = rreq_last;
    assign target_axi_rresp = 2'b00;

    // Fork timing model B, R to tracker & target

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_b (
        .s_valid        (timing_model_bvalid),
        .s_ready        (timing_model_bready),
        .m_valid        ({target_axi_bvalid, tracker_bvalid}),
        .m_ready        ({target_axi_bready, tracker_bready})
    );

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_r (
        .s_valid        (timing_model_rvalid),
        .s_ready        (timing_model_rready),
        .m_valid        ({target_axi_rvalid, tracker_rvalid}),
        .m_ready        ({target_axi_rready, tracker_rready})
    );

    assign `AXI4_B_PAYLOAD(tracker) = `AXI4_B_PAYLOAD(target_axi);
    assign `AXI4_R_PAYLOAD(tracker) = `AXI4_R_PAYLOAD(target_axi);

endmodule

`default_nettype wire
