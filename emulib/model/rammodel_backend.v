`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_backend #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h10000,
    parameter   MAX_INFLIGHT    = 8
)(

    input  wire                 host_clk,
    input  wire                 host_rst,

    input  wire                 target_clk,
    input  wire                 target_rst,

    `AXI4_CUSTOM_A_SLAVE_IF     (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_W_SLAVE_IF     (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_B_MASTER_IF    (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_R_MASTER_IF    (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input  wire                 rreq_valid,
    input  wire [ID_WIDTH-1:0]  rreq_id,

    input  wire                 breq_valid,
    input  wire [ID_WIDTH-1:0]  breq_id,

    `AXI4_MASTER_IF             (host_axi,      ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF_NO_ID       (lsu_axi, 32, 32),

    input  wire                 target_fire,
    output wire                 stall,

    input  wire                 up_req,
    input  wire                 down_req,
    output wire                 up_stat,
    output wire                 down_stat

);

    localparam  W_FIFO_DEPTH    = 256;
    localparam  B_FIFO_DEPTH    = 1;
    localparam  R_FIFO_DEPTH    = 256;

    // Decouple target reset

    wire decoupled_target_rst = target_rst && target_fire;
    wire target_rst_ok;

    // Decouple frontend A, W, B, R

    wire decoupled_avalid, decoupled_aready;
    wire decoupled_wvalid, decoupled_wready;
    wire decoupled_bvalid, decoupled_bready;
    wire decoupled_rvalid, decoupled_rready;

    emulib_ready_valid_decouple #(
        .DECOUPLE_S     (0),
        .DECOUPLE_M     (1)
    ) decouple_a (
        .s_valid        (frontend_avalid),
        .s_ready        (frontend_aready),
        .m_valid        (decoupled_avalid),
        .m_ready        (1'b1),
        .couple         (target_fire)
    );

    emulib_ready_valid_decouple #(
        .DECOUPLE_S     (0),
        .DECOUPLE_M     (1)
    ) decouple_w (
        .s_valid        (frontend_wvalid),
        .s_ready        (frontend_wready),
        .m_valid        (decoupled_wvalid),
        .m_ready        (1'b1),
        .couple         (target_fire)
    );

    emulib_ready_valid_decouple #(
        .DECOUPLE_S     (1),
        .DECOUPLE_M     (0)
    ) decouple_target_b (
        .s_valid        (decoupled_bvalid),
        .s_ready        (decoupled_bready),
        .m_valid        (frontend_bvalid),
        .m_ready        (frontend_bready),
        .couple         (target_fire)
    );

    emulib_ready_valid_decouple #(
        .DECOUPLE_S     (1),
        .DECOUPLE_M     (0)
    ) decouple_target_r (
        .s_valid        (decoupled_rvalid),
        .s_ready        (decoupled_rready),
        .m_valid        (frontend_rvalid),
        .m_ready        (frontend_rready),
        .couple         (target_fire)
    );

    // Decouple frontend BReq, RReq

    wire decoupled_breq_valid = breq_valid && target_fire;
    wire decoupled_rreq_valid = rreq_valid && target_fire;

    // Generate stall signal

    wire a_stall    = frontend_avalid && !decoupled_aready;
    wire w_stall    = frontend_wvalid && !decoupled_wready;
    wire breq_stall = breq_valid && !resp_bvalid;
    wire rreq_stall = rreq_valid && !resp_rvalid;
    wire rst_stall  = target_rst && !target_rst_ok;

    assign stall = a_stall || w_stall || breq_stall || rreq_stall;

    // FIFOs for A, W, B, R

    // [1] = frontend/scheduler, [0] = load/save

    wire [1:0] a_fifo_in_mux_sel, a_fifo_out_mux_sel;
    wire [1:0] w_fifo_in_mux_sel, w_fifo_out_mux_sel;
    wire [1:0] b_fifo_in_mux_sel, b_fifo_out_mux_sel;
    wire [1:0] r_fifo_in_mux_sel, r_fifo_out_mux_sel;

    wire fifo_clear;

    // A FIFO

    `AXI4_CUSTOM_A_WIRE(a_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(a_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(a_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(a_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(sched,         ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) a_fifo_in_mux (
        .s_valid    ({decoupled_avalid, a_fifo_load_avalid}),
        .s_ready    ({decoupled_aready, a_fifo_load_aready}),
        .s_data     ({`AXI4_CUSTOM_A_PAYLOAD(frontend), `AXI4_CUSTOM_A_PAYLOAD(a_fifo_load)}),
        .s_sel      (a_fifo_in_mux_sel),
        .m_valid    (a_fifo_in_avalid),
        .m_ready    (a_fifo_in_aready),
        .m_data     (`AXI4_CUSTOM_A_PAYLOAD(a_fifo_in)),
        .m_sel      (1'b1)
    );

    wire a_fifo_empty;
    wire [$clog2(MAX_INFLIGHT):0] a_fifo_item_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (MAX_INFLIGHT),
        .USE_BURST  (0),
        .USE_SRSW   (0)
    ) a_fifo (
        .clk        (host_clk),
        .rst        (host_rst || fifo_clear),
        .ivalid     (a_fifo_in_avalid),
        .iready     (a_fifo_in_aready),
        .idata      (`AXI4_CUSTOM_A_PAYLOAD(a_fifo_in)),
        .ovalid     (a_fifo_out_avalid),
        .oready     (a_fifo_out_aready),
        .odata      (`AXI4_CUSTOM_A_PAYLOAD(a_fifo_out)),
        .empty      (a_fifo_empty),
        .item_cnt   (a_fifo_item_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) a_fifo_out_mux (
        .s_valid    (a_fifo_out_avalid),
        .s_ready    (a_fifo_out_aready),
        .s_data     (`AXI4_CUSTOM_A_PAYLOAD(a_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({sched_avalid, a_fifo_save_avalid}),
        .m_ready    ({sched_aready, a_fifo_save_aready}),
        .m_data     ({`AXI4_CUSTOM_A_PAYLOAD(sched), `AXI4_CUSTOM_A_PAYLOAD(a_fifo_save)}),
        .m_sel      (a_fifo_out_mux_sel)
    );

    // W FIFO

    `AXI4_CUSTOM_W_WIRE(w_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(w_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(w_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(w_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(sched,         ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_CUSTOM_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) w_fifo_in_mux (
        .s_valid    ({decoupled_wvalid, w_fifo_load_wvalid}),
        .s_ready    ({decoupled_wready, w_fifo_load_wready}),
        .s_data     ({`AXI4_CUSTOM_W_PAYLOAD(frontend), `AXI4_CUSTOM_W_PAYLOAD(w_fifo_load)}),
        .s_sel      (w_fifo_in_mux_sel),
        .m_valid    (w_fifo_in_wvalid),
        .m_ready    (w_fifo_in_wready),
        .m_data     (`AXI4_CUSTOM_W_PAYLOAD(w_fifo_in)),
        .m_sel      (1'b1)
    );

    wire w_fifo_empty;
    wire [$clog2(W_FIFO_DEPTH):0] w_fifo_item_cnt, w_fifo_burst_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_CUSTOM_W_PAYLOAD_WO_LAST_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (W_FIFO_DEPTH),
        .USE_BURST  (1),
        .USE_SRSW   (1)
    ) w_fifo (
        .clk        (host_clk),
        .rst        (host_rst || fifo_clear),
        .ivalid     (w_fifo_in_wvalid),
        .iready     (w_fifo_in_wready),
        .idata      (`AXI4_CUSTOM_W_PAYLOAD_WO_LAST(w_fifo_in)),
        .ilast      (w_fifo_in_wlast),
        .ovalid     (w_fifo_out_wvalid),
        .oready     (w_fifo_out_wready),
        .odata      (`AXI4_CUSTOM_W_PAYLOAD_WO_LAST(w_fifo_out)),
        .olast      (w_fifo_out_wlast),
        .empty      (w_fifo_empty),
        .item_cnt   (w_fifo_item_cnt),
        .burst_cnt  (w_fifo_burst_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) w_fifo_out_mux (
        .s_valid    (w_fifo_out_wvalid),
        .s_ready    (w_fifo_out_wready),
        .s_data     (`AXI4_CUSTOM_W_PAYLOAD(w_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({sched_wvalid, w_fifo_save_wvalid}),
        .m_ready    ({sched_wready, w_fifo_save_wready}),
        .m_data     ({`AXI4_CUSTOM_W_PAYLOAD(sched), `AXI4_CUSTOM_W_PAYLOAD(w_fifo_save)}),
        .m_sel      (w_fifo_out_mux_sel)
    );

    // B FIFO

    `AXI4_CUSTOM_B_WIRE(b_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(b_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(b_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(b_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(resp,          ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_CUSTOM_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) b_fifo_in_mux (
        .s_valid    ({host_axi_bvalid, b_fifo_load_bvalid}),
        .s_ready    ({host_axi_bready, b_fifo_load_bready}),
        .s_data     ({`AXI4_CUSTOM_B_PAYLOAD(host_axi), `AXI4_CUSTOM_B_PAYLOAD(b_fifo_load)}),
        .s_sel      (b_fifo_in_mux_sel),
        .m_valid    (b_fifo_in_bvalid),
        .m_ready    (b_fifo_in_bready),
        .m_data     (`AXI4_CUSTOM_B_PAYLOAD(b_fifo_in)),
        .m_sel      (1'b1)
    );

    wire b_fifo_empty;
    wire [$clog2(B_FIFO_DEPTH):0] b_fifo_item_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_CUSTOM_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (B_FIFO_DEPTH),
        .USE_BURST  (0),
        .USE_SRSW   (0)
    ) b_fifo (
        .clk        (host_clk),
        .rst        (host_rst || fifo_clear),
        .ivalid     (b_fifo_in_bvalid),
        .iready     (b_fifo_in_bready),
        .idata      (`AXI4_CUSTOM_B_PAYLOAD(b_fifo_in)),
        .ovalid     (b_fifo_out_bvalid),
        .oready     (b_fifo_out_bready),
        .odata      (`AXI4_CUSTOM_B_PAYLOAD(b_fifo_out)),
        .empty      (b_fifo_empty),
        .item_cnt   (b_fifo_item_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) b_fifo_out_mux (
        .s_valid    (b_fifo_out_bvalid),
        .s_ready    (b_fifo_out_bready),
        .s_data     (`AXI4_CUSTOM_B_PAYLOAD(b_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({resp_bvalid, b_fifo_save_bvalid}),
        .m_ready    ({resp_bready, b_fifo_save_bready}),
        .m_data     ({`AXI4_CUSTOM_B_PAYLOAD(resp), `AXI4_CUSTOM_B_PAYLOAD(b_fifo_save)}),
        .m_sel      (b_fifo_out_mux_sel)
    );

    // R FIFO

    `AXI4_CUSTOM_R_WIRE(r_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(r_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(r_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(r_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(resp,          ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_CUSTOM_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) r_fifo_in_mux (
        .s_valid    ({host_axi_rvalid, r_fifo_load_rvalid}),
        .s_ready    ({host_axi_rready, r_fifo_load_rready}),
        .s_data     ({`AXI4_CUSTOM_R_PAYLOAD(host_axi), `AXI4_CUSTOM_R_PAYLOAD(r_fifo_load)}),
        .s_sel      (r_fifo_in_mux_sel),
        .m_valid    (r_fifo_in_rvalid),
        .m_ready    (r_fifo_in_rready),
        .m_data     (`AXI4_CUSTOM_R_PAYLOAD(r_fifo_in)),
        .m_sel      (1'b1)
    );

    wire r_fifo_empty;
    wire [$clog2(R_FIFO_DEPTH):0] r_fifo_item_cnt, r_fifo_burst_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_CUSTOM_R_PAYLOAD_WO_LAST_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (R_FIFO_DEPTH),
        .USE_BURST  (1),
        .USE_SRSW   (1)
    ) r_fifo (
        .clk        (host_clk),
        .rst        (host_rst || fifo_clear),
        .ivalid     (r_fifo_in_rvalid),
        .iready     (r_fifo_in_rready),
        .idata      (`AXI4_CUSTOM_R_PAYLOAD_WO_LAST(r_fifo_in)),
        .ilast      (r_fifo_in_rlast),
        .ovalid     (r_fifo_out_rvalid),
        .oready     (r_fifo_out_rready),
        .odata      (`AXI4_CUSTOM_R_PAYLOAD_WO_LAST(r_fifo_out)),
        .olast      (r_fifo_out_rlast),
        .empty      (r_fifo_empty),
        .item_cnt   (r_fifo_item_cnt),
        .burst_cnt  (r_fifo_burst_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) r_fifo_out_mux (
        .s_valid    (r_fifo_out_rvalid),
        .s_ready    (r_fifo_out_rready),
        .s_data     (`AXI4_CUSTOM_R_PAYLOAD(r_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({resp_rvalid, r_fifo_save_rvalid}),
        .m_ready    ({resp_rready, r_fifo_save_rready}),
        .m_data     ({`AXI4_CUSTOM_R_PAYLOAD(resp), `AXI4_CUSTOM_R_PAYLOAD(r_fifo_save)}),
        .m_sel      (r_fifo_out_mux_sel)
    );

    // Gate A & W requests

    wire sched_enable_a, sched_enable_w;

    wire gated_sched_avalid, gated_sched_aready;
    wire gated_sched_wvalid, gated_sched_wready;

    emulib_ready_valid_decouple #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_sched_a (
        .s_valid    (sched_avalid),
        .s_ready    (sched_aready),
        .m_valid    (gated_sched_avalid),
        .m_ready    (gated_sched_aready),
        .couple     (sched_enable_a)
    );

    emulib_ready_valid_decouple #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_sched_w (
        .s_valid    (sched_wvalid),
        .s_ready    (sched_wready),
        .m_valid    (gated_sched_wvalid),
        .m_ready    (gated_sched_wready),
        .couple     (sched_enable_w)
    );

    // Gate B & R responses

    emulib_ready_valid_decouple #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_resp_b (
        .s_valid    (resp_bvalid),
        .s_ready    (resp_bready),
        .m_valid    (decoupled_bvalid),
        .m_ready    (decoupled_bready),
        .couple     (decoupled_breq_valid)
    );

    emulib_ready_valid_decouple #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_resp_r (
        .s_valid    (resp_rvalid),
        .s_ready    (resp_rready),
        .m_valid    (decoupled_rvalid),
        .m_ready    (decoupled_rready),
        .couple     (decoupled_rreq_valid)
    );

    assign `AXI4_CUSTOM_B_PAYLOAD(frontend) = `AXI4_CUSTOM_B_PAYLOAD(resp);
    assign `AXI4_CUSTOM_R_PAYLOAD(frontend) = `AXI4_CUSTOM_R_PAYLOAD(resp);

    // Route A to AW/AR

    `AXI4_CUSTOM_A_WIRE(routed_aw, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(routed_ar, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) a_router (
        .s_valid    (gated_sched_avalid),
        .s_ready    (gated_sched_aready),
        .s_data     (`AXI4_CUSTOM_A_PAYLOAD(sched)),
        .s_sel      (1'b1),
        .m_valid    ({routed_aw_avalid, routed_ar_avalid}),
        .m_ready    ({routed_aw_aready, routed_ar_aready}),
        .m_data     ({`AXI4_CUSTOM_A_PAYLOAD(routed_aw), `AXI4_CUSTOM_A_PAYLOAD(routed_ar)}),
        .m_sel      ({sched_awrite, ~sched_awrite})
    );

    assign host_axi_awvalid     = routed_aw_avalid;
    assign routed_aw_aready     = host_axi_awready;
    assign host_axi_awaddr      = routed_aw_aaddr;
    assign host_axi_awid        = 0; // TODO
    assign host_axi_awlen       = routed_aw_alen;
    assign host_axi_awsize      = routed_aw_asize;
    assign host_axi_awburst     = routed_aw_aburst;
    assign host_axi_awprot      = 3'b010;
    assign host_axi_awlock      = 1'b0;
    assign host_axi_awcache     = 4'd0;
    assign host_axi_awqos       = 4'd0;
    assign host_axi_awregion    = 4'd0;

    assign host_axi_wvalid      = gated_sched_wvalid;
    assign gated_sched_wready   = host_axi_wready;
    assign `AXI4_CUSTOM_W_PAYLOAD(host_axi) = `AXI4_CUSTOM_W_PAYLOAD(sched);

    assign host_axi_arvalid     = routed_ar_avalid;
    assign routed_ar_aready     = host_axi_arready;
    assign host_axi_araddr      = routed_ar_aaddr;
    assign host_axi_arid        = 0; // TODO
    assign host_axi_arlen       = routed_ar_alen;
    assign host_axi_arsize      = routed_ar_asize;
    assign host_axi_arburst     = routed_ar_aburst;
    assign host_axi_arprot      = 3'b010;
    assign host_axi_arlock      = 1'b0;
    assign host_axi_arcache     = 4'd0;
    assign host_axi_arqos       = 4'd0;
    assign host_axi_arregion    = 4'd0;

    // Scheduler & responser FSMs

    wire sched_afire    = sched_avalid && sched_aready;
    wire sched_wfire    = sched_wvalid && sched_wready;
    wire host_axi_bfire = host_axi_bvalid && host_axi_bready;
    wire host_axi_rfire = host_axi_rvalid && host_axi_rready;
    wire resp_rfire     = resp_rvalid && resp_rready;
    wire resp_bfire     = resp_bvalid && resp_bready;

    localparam [2:0]
        SCHED_IDLE  = 3'd0,
        SCHED_DO_A  = 3'd1,
        SCHED_DO_W  = 3'd2,
        SCHED_DO_R  = 3'd3,
        SCHED_DO_B  = 3'd4;

    reg [2:0] sched_state, sched_state_next;

    wire sched_ok_to_ar = sched_avalid && !sched_awrite;
    wire sched_ok_to_aw = sched_avalid && sched_awrite && w_fifo_burst_cnt != 0;
    wire sched_ok_to_a = (sched_ok_to_ar || sched_ok_to_aw) && b_fifo_empty && r_fifo_empty && up_stat && !down_req;

    always @(posedge host_clk)
        if (host_rst)
            sched_state <= SCHED_IDLE;
        else
            sched_state <= sched_state_next;

    always @*
        case (sched_state)
        SCHED_IDLE:
            if (sched_ok_to_a)
                sched_state_next = SCHED_DO_A;
            else
                sched_state_next = SCHED_IDLE;
        SCHED_DO_A:
            if (sched_afire)
                sched_state_next = sched_awrite ? SCHED_DO_W : SCHED_DO_R;
            else
                sched_state_next = SCHED_DO_A;
        SCHED_DO_R:
            if (host_axi_rfire && host_axi_rlast)
                sched_state_next = SCHED_IDLE;
            else
                sched_state_next = SCHED_DO_R;
        SCHED_DO_W:
            if (sched_wfire && sched_wlast)
                sched_state_next = SCHED_DO_B;
            else
                sched_state_next = SCHED_DO_W;
        SCHED_DO_B:
            if (host_axi_bfire)
                sched_state_next = SCHED_IDLE;
            else
                sched_state_next = SCHED_DO_B;
        default:
            sched_state_next = SCHED_IDLE;
        endcase

    assign sched_enable_a   = sched_state == SCHED_DO_A;
    assign sched_enable_w   = sched_state == SCHED_DO_W;

`ifdef SIM_LOG

    function [255:0] sched_state_name(input [2:0] arg_state);
        begin
            case (arg_state)
                SCHED_IDLE:     sched_state_name = "IDLE";
                SCHED_DO_A:     sched_state_name = "DO_A";
                SCHED_DO_W:     sched_state_name = "DO_W";
                SCHED_DO_R:     sched_state_name = "DO_R";
                SCHED_DO_B:     sched_state_name = "DO_B";
                default:        sched_state_name = "<UNK>";
            endcase
        end
    endfunction

    always @(posedge host_clk) begin
        if (!host_rst) begin
            if (sched_state != sched_state_next) begin
                $display("[%0d ns] %m: sched_state %0s -> %0s", $time,
                    sched_state_name(sched_state),
                    sched_state_name(sched_state_next));
            end
        end
    end

`endif

    // Reset handler

    localparam [1:0]
        RST_IDLE    = 2'd0,
        RST_FIRE    = 2'd1,
        RST_DONE    = 2'd2;

    reg [1:0] rst_state, rst_state_next;

    always @(posedge host_clk)
        if (host_rst)
            rst_state <= RST_IDLE;
        else
            rst_state <= rst_state_next;

    always @*
        case (rst_state)
        RST_IDLE:
            if (decoupled_target_rst && sched_state == SCHED_IDLE)
                rst_state_next = RST_FIRE;
            else
                rst_state_next = RST_IDLE;
        RST_FIRE:
            rst_state_next = RST_DONE;
        RST_DONE:
            if (target_fire && !target_rst)
                rst_state_next = RST_IDLE;
            else
                rst_state_next = RST_DONE;
        default:
            rst_state_next = RST_IDLE;
        endcase

    assign target_rst_ok    = rst_state == RST_DONE;
    assign fifo_clear       = rst_state == RST_FIRE;

    // State LSU (load/save unit)

    wire lsu_save, lsu_load, lsu_complete;
    wire sched_idle;

    wire [31:0] fifo_a_cnt  = a_fifo_item_cnt;
    wire [31:0] fifo_w_cnt  = w_fifo_item_cnt;
    wire [31:0] fifo_b_cnt  = b_fifo_item_cnt;
    wire [31:0] fifo_r_cnt  = r_fifo_item_cnt;

    emulib_rammodel_state_lsu #(
        .ADDR_WIDTH             (ADDR_WIDTH),
        .DATA_WIDTH             (DATA_WIDTH),
        .ID_WIDTH               (ID_WIDTH)
    ) u_state_lsu (

        .clk                    (host_clk),
        .rst                    (host_rst),

        .save                   (lsu_save),
        .load                   (lsu_load),
        .complete               (lsu_complete),

        `AXI4_CUSTOM_A_CONNECT  (fifo_save, a_fifo_save),
        `AXI4_CUSTOM_W_CONNECT  (fifo_save, w_fifo_save),
        `AXI4_CUSTOM_B_CONNECT  (fifo_save, b_fifo_save),
        `AXI4_CUSTOM_R_CONNECT  (fifo_save, r_fifo_save),

        `AXI4_CUSTOM_A_CONNECT  (fifo_load, a_fifo_load),
        `AXI4_CUSTOM_W_CONNECT  (fifo_load, w_fifo_load),
        `AXI4_CUSTOM_B_CONNECT  (fifo_load, b_fifo_load),
        `AXI4_CUSTOM_R_CONNECT  (fifo_load, r_fifo_load),

        .fifo_a_cnt             (fifo_a_cnt),
        .fifo_w_cnt             (fifo_w_cnt),
        .fifo_b_cnt             (fifo_b_cnt),
        .fifo_r_cnt             (fifo_r_cnt),

        `AXI4_CONNECT_NO_ID     (host_axi, lsu_axi)

    );

    localparam [1:0]
        LS_STATE_UP     = 2'd0,
        LS_STATE_SAVE   = 2'd1,
        LS_STATE_LOAD   = 2'd2,
        LS_STATE_DOWN   = 2'd3;

    reg [1:0] ls_state, ls_state_next;

    always @(posedge host_clk)
        if (host_rst)
            ls_state <= LS_STATE_UP;
        else
            ls_state <= ls_state_next;

    always @*
        case (ls_state)
        LS_STATE_UP:
            if (down_req && sched_state == SCHED_IDLE)
                ls_state_next = LS_STATE_SAVE;
            else
                ls_state_next = LS_STATE_UP;
        LS_STATE_SAVE:
            if (lsu_complete)
                ls_state_next = LS_STATE_DOWN;
            else
                ls_state_next = LS_STATE_SAVE;
        LS_STATE_DOWN:
            if (up_req)
                ls_state_next = LS_STATE_LOAD;
            else
                ls_state_next = LS_STATE_DOWN;
        LS_STATE_LOAD:
            if (lsu_complete)
                ls_state_next = LS_STATE_UP;
            else
                ls_state_next = LS_STATE_LOAD;
        default:
            ls_state_next = LS_STATE_UP;
        endcase

    assign lsu_save     = ls_state == LS_STATE_SAVE;
    assign lsu_load     = ls_state == LS_STATE_LOAD;
    assign up_stat      = ls_state == LS_STATE_UP;
    assign down_stat    = ls_state == LS_STATE_DOWN;

    wire [1:0] fifo_sel = {up_stat, lsu_save || lsu_load};

    assign a_fifo_in_mux_sel    = fifo_sel;
    assign w_fifo_in_mux_sel    = fifo_sel;
    assign b_fifo_in_mux_sel    = fifo_sel;
    assign r_fifo_in_mux_sel    = fifo_sel;
    assign a_fifo_out_mux_sel   = fifo_sel;
    assign w_fifo_out_mux_sel   = fifo_sel;
    assign b_fifo_out_mux_sel   = fifo_sel;
    assign r_fifo_out_mux_sel   = fifo_sel;

`ifdef SIM_LOG

    function [255:0] ls_state_name(input [2:0] arg_state);
        begin
            case (arg_state)
                LS_STATE_UP:    ls_state_name = "UP";
                LS_STATE_SAVE:  ls_state_name = "SAVE";
                LS_STATE_LOAD:  ls_state_name = "LOAD";
                LS_STATE_DOWN:  ls_state_name = "DOWN";
                default:        ls_state_name = "<UNK>";
            endcase
        end
    endfunction

    always @(posedge host_clk) begin
        if (!host_rst) begin
            if (ls_state != ls_state_next) begin
                $display("[%0d ns] %m: ls_state %0s -> %0s", $time,
                    ls_state_name(ls_state),
                    ls_state_name(ls_state_next));
            end
        end
    end

`endif

endmodule

`resetall
