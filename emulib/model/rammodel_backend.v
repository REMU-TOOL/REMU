`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_a.vh"

(* __emu_directive = "ignore" *)

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

    `AXI4_A_SLAVE_IF            (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_W_SLAVE_IF            (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_B_MASTER_IF           (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_R_MASTER_IF           (frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input  wire                 rreq_valid,
    input  wire [ID_WIDTH-1:0]  rreq_id,

    input  wire                 breq_valid,
    input  wire [ID_WIDTH-1:0]  breq_id,

    `AXI4_MASTER_IF             (host_axi,      ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

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
    wire decoupled_breq_ready;
    wire decoupled_rreq_valid = rreq_valid && target_fire;
    wire decoupled_rreq_ready;

    // Generate stall signal

    wire a_stall    = frontend_avalid && !decoupled_aready;
    wire w_stall    = frontend_wvalid && !decoupled_wready;
    wire breq_stall = breq_valid && !decoupled_breq_ready;
    wire rreq_stall = rreq_valid && !decoupled_rreq_ready;

    assign stall = a_stall || w_stall || breq_stall || rreq_stall;

    // FIFOs for A, W, B, R

    // [1] = frontend/scheduler, [0] = load/save

    wire [1:0] a_fifo_in_mux_sel, a_fifo_out_mux_sel;
    wire [1:0] w_fifo_in_mux_sel, w_fifo_out_mux_sel;
    wire [1:0] b_fifo_in_mux_sel, b_fifo_out_mux_sel;
    wire [1:0] r_fifo_in_mux_sel, r_fifo_out_mux_sel;

    // A FIFO

    `AXI4_A_WIRE(a_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_A_WIRE(a_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_A_WIRE(a_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_A_WIRE(a_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_A_WIRE(sched,         ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) a_fifo_in_mux (
        .s_valid    ({decoupled_avalid, a_fifo_load_avalid}),
        .s_ready    ({decoupled_aready, a_fifo_load_aready}),
        .s_data     ({`AXI4_A_PAYLOAD(frontend), `AXI4_A_PAYLOAD(a_fifo_load)}),
        .s_sel      (a_fifo_in_mux_sel),
        .m_valid    (a_fifo_in_avalid),
        .m_ready    (a_fifo_in_aready),
        .m_data     (`AXI4_A_PAYLOAD(a_fifo_in)),
        .m_sel      (1'b1)
    );

    wire [$clog2(MAX_INFLIGHT):0] a_fifo_item_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (MAX_INFLIGHT),
        .USE_BURST  (0),
        .USE_SRSW   (0)
    ) a_fifo (
        .clk        (host_clk),
        .rst        (host_rst),
        .ivalid     (a_fifo_in_avalid),
        .iready     (a_fifo_in_aready),
        .idata      (`AXI4_A_PAYLOAD(a_fifo_in)),
        .ovalid     (a_fifo_out_avalid),
        .oready     (a_fifo_out_aready),
        .odata      (`AXI4_A_PAYLOAD(a_fifo_out)),
        .item_cnt   (a_fifo_item_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) a_fifo_out_mux (
        .s_valid    (a_fifo_out_avalid),
        .s_ready    (a_fifo_out_aready),
        .s_data     (`AXI4_A_PAYLOAD(a_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({sched_avalid, a_fifo_save_avalid}),
        .m_ready    ({sched_aready, a_fifo_save_aready}),
        .m_data     ({`AXI4_A_PAYLOAD(sched), `AXI4_A_PAYLOAD(a_fifo_save)}),
        .m_sel      (a_fifo_out_mux_sel)
    );

    // W FIFO

    `AXI4_W_WIRE(w_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_W_WIRE(w_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_W_WIRE(w_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_W_WIRE(w_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_W_WIRE(sched,         ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) w_fifo_in_mux (
        .s_valid    ({decoupled_wvalid, w_fifo_load_wvalid}),
        .s_ready    ({decoupled_wready, w_fifo_load_wready}),
        .s_data     ({`AXI4_W_PAYLOAD(frontend), `AXI4_W_PAYLOAD(w_fifo_load)}),
        .s_sel      (w_fifo_in_mux_sel),
        .m_valid    (w_fifo_in_wvalid),
        .m_ready    (w_fifo_in_wready),
        .m_data     (`AXI4_W_PAYLOAD(w_fifo_in)),
        .m_sel      (1'b1)
    );

    wire [$clog2(W_FIFO_DEPTH):0] w_fifo_item_cnt, w_fifo_burst_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH) - 1),
        .DEPTH      (W_FIFO_DEPTH),
        .USE_BURST  (1),
        .USE_SRSW   (1)
    ) w_fifo (
        .clk        (host_clk),
        .rst        (host_rst),
        .ivalid     (w_fifo_in_wvalid),
        .iready     (w_fifo_in_wready),
        .idata      (`AXI4_W_PAYLOAD_WO_LAST(w_fifo_in)),
        .ilast      (w_fifo_in_wlast),
        .ovalid     (w_fifo_out_wvalid),
        .oready     (w_fifo_out_wready),
        .odata      (`AXI4_W_PAYLOAD_WO_LAST(w_fifo_out)),
        .olast      (w_fifo_out_wlast),
        .item_cnt   (w_fifo_item_cnt),
        .burst_cnt  (w_fifo_burst_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) w_fifo_out_mux (
        .s_valid    (w_fifo_out_wvalid),
        .s_ready    (w_fifo_out_wready),
        .s_data     (`AXI4_W_PAYLOAD(w_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({sched_wvalid, w_fifo_save_wvalid}),
        .m_ready    ({sched_wready, w_fifo_save_wready}),
        .m_data     ({`AXI4_W_PAYLOAD(sched), `AXI4_W_PAYLOAD(w_fifo_save)}),
        .m_sel      (w_fifo_out_mux_sel)
    );

    // B FIFO

    `AXI4_B_WIRE(b_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_B_WIRE(b_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_B_WIRE(b_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_B_WIRE(b_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_B_WIRE(resp,          ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) b_fifo_in_mux (
        .s_valid    ({host_axi_bvalid, b_fifo_load_bvalid}),
        .s_ready    ({host_axi_bready, b_fifo_load_bready}),
        .s_data     ({`AXI4_B_PAYLOAD(host_axi), `AXI4_B_PAYLOAD(b_fifo_load)}),
        .s_sel      (b_fifo_in_mux_sel),
        .m_valid    (b_fifo_in_bvalid),
        .m_ready    (b_fifo_in_bready),
        .m_data     (`AXI4_B_PAYLOAD(b_fifo_in)),
        .m_sel      (1'b1)
    );

    wire b_fifo_empty;
    wire [$clog2(B_FIFO_DEPTH):0] b_fifo_item_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (B_FIFO_DEPTH),
        .USE_BURST  (0),
        .USE_SRSW   (0)
    ) b_fifo (
        .clk        (host_clk),
        .rst        (host_rst),
        .ivalid     (b_fifo_in_bvalid),
        .iready     (b_fifo_in_bready),
        .idata      (`AXI4_B_PAYLOAD(b_fifo_in)),
        .ovalid     (b_fifo_out_bvalid),
        .oready     (b_fifo_out_bready),
        .odata      (`AXI4_B_PAYLOAD(b_fifo_out)),
        .empty      (b_fifo_empty),
        .item_cnt   (b_fifo_item_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) b_fifo_out_mux (
        .s_valid    (b_fifo_out_bvalid),
        .s_ready    (b_fifo_out_bready),
        .s_data     (`AXI4_B_PAYLOAD(b_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({resp_bvalid, b_fifo_save_bvalid}),
        .m_ready    ({resp_bready, b_fifo_save_bready}),
        .m_data     ({`AXI4_B_PAYLOAD(resp), `AXI4_B_PAYLOAD(b_fifo_save)}),
        .m_sel      (b_fifo_out_mux_sel)
    );

    // R FIFO

    `AXI4_R_WIRE(r_fifo_load,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_R_WIRE(r_fifo_in,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_R_WIRE(r_fifo_out,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_R_WIRE(r_fifo_save,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_R_WIRE(resp,          ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (2),
        .NUM_M      (1),
        .DATA_WIDTH (`AXI4_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) r_fifo_in_mux (
        .s_valid    ({host_axi_rvalid, r_fifo_load_rvalid}),
        .s_ready    ({host_axi_rready, r_fifo_load_rready}),
        .s_data     ({`AXI4_R_PAYLOAD(host_axi), `AXI4_R_PAYLOAD(r_fifo_load)}),
        .s_sel      (r_fifo_in_mux_sel),
        .m_valid    (r_fifo_in_rvalid),
        .m_ready    (r_fifo_in_rready),
        .m_data     (`AXI4_R_PAYLOAD(r_fifo_in)),
        .m_sel      (1'b1)
    );

    wire r_fifo_empty;
    wire [$clog2(R_FIFO_DEPTH):0] r_fifo_item_cnt, r_fifo_burst_cnt;

    emulib_fifo #(
        .WIDTH      (`AXI4_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH) - 1),
        .DEPTH      (R_FIFO_DEPTH),
        .USE_BURST  (1),
        .USE_SRSW   (1)
    ) r_fifo (
        .clk        (host_clk),
        .rst        (host_rst),
        .ivalid     (r_fifo_in_rvalid),
        .iready     (r_fifo_in_rready),
        .idata      (`AXI4_R_PAYLOAD_WO_LAST(r_fifo_in)),
        .ilast      (r_fifo_in_rlast),
        .ovalid     (r_fifo_out_rvalid),
        .oready     (r_fifo_out_rready),
        .odata      (`AXI4_R_PAYLOAD_WO_LAST(r_fifo_out)),
        .olast      (r_fifo_out_rlast),
        .empty      (r_fifo_empty),
        .item_cnt   (r_fifo_item_cnt),
        .burst_cnt  (r_fifo_burst_cnt)
    );

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) r_fifo_out_mux (
        .s_valid    (r_fifo_out_rvalid),
        .s_ready    (r_fifo_out_rready),
        .s_data     (`AXI4_R_PAYLOAD(r_fifo_out)),
        .s_sel      (1'b1),
        .m_valid    ({resp_rvalid, r_fifo_save_rvalid}),
        .m_ready    ({resp_rready, r_fifo_save_rready}),
        .m_data     ({`AXI4_R_PAYLOAD(resp), `AXI4_R_PAYLOAD(r_fifo_save)}),
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

    wire resp_enable_b, resp_enable_r;

    emulib_ready_valid_decouple #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_resp_b (
        .s_valid    (resp_bvalid),
        .s_ready    (resp_bready),
        .m_valid    (decoupled_bvalid),
        .m_ready    (decoupled_bready),
        .couple     (resp_enable_b)
    );

    emulib_ready_valid_decouple #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_resp_r (
        .s_valid    (resp_rvalid),
        .s_ready    (resp_rready),
        .m_valid    (decoupled_rvalid),
        .m_ready    (decoupled_rready),
        .couple     (resp_enable_r)
    );

    assign `AXI4_B_PAYLOAD(frontend) = `AXI4_B_PAYLOAD(resp);
    assign `AXI4_R_PAYLOAD(frontend) = `AXI4_R_PAYLOAD(resp);

    // Route A to AW/AR

    `AXI4_A_WIRE(routed_aw, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_A_WIRE(routed_ar, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_S      (1),
        .NUM_M      (2),
        .DATA_WIDTH (`AXI4_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) a_router (
        .s_valid    (gated_sched_avalid),
        .s_ready    (gated_sched_aready),
        .s_data     (`AXI4_A_PAYLOAD(sched)),
        .s_sel      (1'b1),
        .m_valid    ({routed_aw_avalid, routed_ar_avalid}),
        .m_ready    ({routed_aw_aready, routed_ar_aready}),
        .m_data     ({`AXI4_A_PAYLOAD(routed_aw), `AXI4_A_PAYLOAD(routed_ar)}),
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
    assign `AXI4_W_PAYLOAD(host_axi) = `AXI4_W_PAYLOAD(sched);

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

    // Save/load FSM

    // TODO

    assign a_fifo_load_avalid = 1'b0;
    assign a_fifo_save_aready = 1'b0;
    assign w_fifo_load_wvalid = 1'b0;
    assign w_fifo_save_wready = 1'b0;
    assign b_fifo_load_bvalid = 1'b0;
    assign b_fifo_save_bready = 1'b0;
    assign r_fifo_load_rvalid = 1'b0;
    assign r_fifo_save_rready = 1'b0;

    assign a_fifo_in_mux_sel = 2'b10;
    assign w_fifo_in_mux_sel = 2'b10;
    assign b_fifo_in_mux_sel = 2'b10;
    assign r_fifo_in_mux_sel = 2'b10;
    assign a_fifo_out_mux_sel = 2'b10;
    assign w_fifo_out_mux_sel = 2'b10;
    assign b_fifo_out_mux_sel = 2'b10;
    assign r_fifo_out_mux_sel = 2'b10;

    assign up_stat      = 1'b1;
    assign down_stat    = 1'b0;

    // Scheduler FSM

    wire sched_afire    = sched_avalid && sched_aready;
    wire sched_wfire    = sched_wvalid && sched_wready;
    wire resp_rfire     = resp_rvalid && resp_rready;
    wire resp_bfire     = resp_bvalid && resp_bready;

    localparam [2:0]
        IDLE = 3'd0,
        DO_A = 3'd1,
        DO_W = 3'd2,
        DO_R = 3'd3,
        DO_B = 3'd4,
        WAIT_R = 3'd5,
        WAIT_B = 3'd6;

    reg [2:0] sched_state, sched_state_next;

    always @(posedge host_clk)
        if (host_rst)
            sched_state <= IDLE;
        else
            sched_state <= sched_state_next;

    always @*
        case (sched_state)
            IDLE:
                if (b_fifo_empty && r_fifo_empty)
                    sched_state_next = DO_A;
                else
                    sched_state_next = IDLE;
            DO_A:
                if (sched_afire)
                    sched_state_next = sched_awrite ? DO_W : WAIT_R;
                else
                    sched_state_next = DO_A;
            WAIT_R:
                if (decoupled_rreq_valid)
                    sched_state_next = DO_R;
                else
                    sched_state_next = WAIT_R;
            DO_R:
                if (resp_rfire && resp_rlast)
                    sched_state_next = IDLE;
                else
                    sched_state_next = DO_R;
            DO_W:
                if (sched_wfire && sched_wlast)
                    sched_state_next = WAIT_B;
                else
                    sched_state_next = DO_W;
            WAIT_B:
                if (decoupled_breq_valid)
                    sched_state_next = DO_B;
                else
                    sched_state_next = WAIT_B;
            DO_B:
                if (resp_bfire)
                    sched_state_next = IDLE;
                else
                    sched_state_next = DO_B;
            default:
                sched_state_next = IDLE;
        endcase

`ifdef SIM_LOG

    function [255:0] sim_sched_state_name(input [2:0] state);
        begin
            case (state)
                IDLE:       sim_sched_state_name = "IDLE";
                DO_A:       sim_sched_state_name = "DO_A";
                DO_W:       sim_sched_state_name = "DO_W";
                DO_R:       sim_sched_state_name = "DO_R";
                DO_B:       sim_sched_state_name = "DO_B";
                WAIT_R:     sim_sched_state_name = "WAIT_R";
                WAIT_B:     sim_sched_state_name = "WAIT_B";
                default:    sim_sched_state_name = "<UNK>";
            endcase
        end
    endfunction

    always @(posedge host_clk) begin
        if (!host_rst) begin
            if (sched_state != sched_state_next) begin
                $display("[%0d ns] %m: sched_state %0s -> %0s", $time,
                    sim_sched_state_name(sched_state),
                    sim_sched_state_name(sched_state_next));
            end
        end
    end

`endif

    assign sched_enable_a   = sched_state == DO_A;
    assign sched_enable_w   = sched_state == DO_W;
    assign resp_enable_b    = sched_state == DO_B;
    assign resp_enable_r    = sched_state == DO_R;

    // BReq/RReq response

    // TODO: find a proper way to handle BReq/RReq when target B/R response is in progress
    assign decoupled_breq_ready = b_fifo_item_cnt != 0;
    assign decoupled_rreq_ready = r_fifo_burst_cnt != 0;

endmodule

`resetall
