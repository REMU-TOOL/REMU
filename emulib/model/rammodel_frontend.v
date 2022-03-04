`resetall
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

    input  wire                 target_clk,
    input  wire                 target_rst,

    `AXI4_SLAVE_IF              (target_axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    `AXI4_CUSTOM_A_MASTER_IF    (backend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_W_MASTER_IF    (backend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_B_SLAVE_IF     (backend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_R_SLAVE_IF     (backend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 rreq_valid,
    output wire [ID_WIDTH-1:0]  rreq_id,

    output wire                 breq_valid,
    output wire [ID_WIDTH-1:0]  breq_id

);

    `AXI4_WIRE(tracker, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    wire timing_model_awvalid, timing_model_awready;
    wire timing_model_wvalid, timing_model_wready;
    wire timing_model_arvalid, timing_model_arready;

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
        .ADDR_WIDTH         (ADDR_WIDTH),
        .DATA_WIDTH         (DATA_WIDTH),
        .ID_WIDTH           (ID_WIDTH),
        .MAX_INFLIGHT       (MAX_INFLIGHT)
    ) tracker (
        .target_clk             (target_clk),
        .target_rst             (target_rst),
        `AXI4_CONNECT           (axi, tracker),
        `AXI4_CUSTOM_A_CONNECT  (backend, backend),
        `AXI4_CUSTOM_W_CONNECT  (backend, backend)
    );

    // Timing model

    emulib_rammodel_tm_fixed #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .R_DELAY    (R_DELAY),
        .W_DELAY    (W_DELAY)
    )
    timing_model (
        .clk        (target_clk),
        .rst        (target_rst),
        .arvalid    (timing_model_arvalid),
        .arready    (timing_model_arready),
        .araddr     (target_axi_araddr),
        .arlen      (target_axi_arlen),
        .arsize     (target_axi_arsize),
        .arburst    (target_axi_arburst),
        .awvalid    (timing_model_awvalid),
        .awready    (timing_model_awready),
        .awaddr     (target_axi_awaddr),
        .awlen      (target_axi_awlen),
        .awsize     (target_axi_awsize),
        .awburst    (target_axi_awburst),
        .wvalid     (timing_model_wvalid),
        .wready     (timing_model_wready),
        .wlast      (target_axi_wlast),
        .rreq_valid (rreq_valid),
        .breq_valid (breq_valid)
    );

    assign rreq_id = 0; // TODO
    assign breq_id = 0; // TODO

    // Fork backend B, R to tracker & target

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_b (
        .s_valid        (backend_bvalid),
        .s_ready        (backend_bready),
        .m_valid        ({target_axi_bvalid, tracker_bvalid}),
        .m_ready        ({target_axi_bready, tracker_bready})
    );

    assign `AXI4_CUSTOM_B_PAYLOAD(tracker) = `AXI4_CUSTOM_B_PAYLOAD(backend);
    assign tracker_bresp = 2'b00;
    assign `AXI4_CUSTOM_B_PAYLOAD(target_axi) = `AXI4_CUSTOM_B_PAYLOAD(backend);
    assign target_axi_bresp = 2'b00;

    emulib_ready_valid_fork #(.BRANCHES(2)) fork_r (
        .s_valid        (backend_rvalid),
        .s_ready        (backend_rready),
        .m_valid        ({target_axi_rvalid, tracker_rvalid}),
        .m_ready        ({target_axi_rready, tracker_rready})
    );

    assign `AXI4_CUSTOM_R_PAYLOAD(tracker) = `AXI4_CUSTOM_R_PAYLOAD(backend);
    assign tracker_rresp = 2'b00;
    assign `AXI4_CUSTOM_R_PAYLOAD(target_axi) = `AXI4_CUSTOM_R_PAYLOAD(backend);
    assign target_axi_rresp = 2'b00;

endmodule

`resetall
