`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_custom.vh"

(* keep, __emu_model_imp *)
module emulib_rammodel_backend #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h10000,
    parameter   MAX_INFLIGHT    = 8
)(

    (* __emu_model_common_port = "mdl_clk" *)
    input  wire                     mdl_clk,
    (* __emu_model_common_port = "mdl_rst" *)
    input  wire                     mdl_rst,

    input  wire                     clk,

    // Reset Channel

    (* __emu_model_channel_name = "rst"*)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "rst" *)
    (* __emu_model_channel_valid = "tk_rst_valid" *)
    (* __emu_model_channel_ready = "tk_rst_ready" *)

    input  wire                     tk_rst_valid,
    output wire                     tk_rst_ready,

    input  wire                     rst,

    // AReq Channel

    (* __emu_model_channel_name = "areq" *)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "areq_*" *)
    (* __emu_model_channel_valid = "tk_areq_valid" *)
    (* __emu_model_channel_ready = "tk_areq_ready" *)

    input  wire                     tk_areq_valid,
    output wire                     tk_areq_ready,

    input  wire                     areq_valid,
    input  wire                     areq_write,
    input  wire [ID_WIDTH-1:0]      areq_id,
    input  wire [ADDR_WIDTH-1:0]    areq_addr,
    input  wire [7:0]               areq_len,
    input  wire [2:0]               areq_size,
    input  wire [1:0]               areq_burst,

    // WReq Channel

    (* __emu_model_channel_name = "wreq" *)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "areq_*" *)
    (* __emu_model_channel_valid = "tk_wreq_valid" *)
    (* __emu_model_channel_ready = "tk_wreq_ready" *)

    input  wire                     tk_wreq_valid,
    output wire                     tk_wreq_ready,

    input  wire                     wreq_valid,
    input  wire [DATA_WIDTH-1:0]    wreq_data,
    input  wire [DATA_WIDTH/8-1:0]  wreq_strb,
    input  wire                     wreq_last,

    // BReq Channel

    (* __emu_model_channel_name = "breq" *)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "breq_*" *)
    (* __emu_model_channel_valid = "tk_breq_valid" *)
    (* __emu_model_channel_ready = "tk_breq_ready" *)

    input  wire                     tk_breq_valid,
    output wire                     tk_breq_ready,

    input  wire                     breq_valid,
    input  wire [ID_WIDTH-1:0]      breq_id,

    // RReq Channel

    (* __emu_model_channel_name = "rreq" *)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "rreq_*" *)
    (* __emu_model_channel_valid = "tk_rreq_valid" *)
    (* __emu_model_channel_ready = "tk_rreq_ready" *)

    input  wire                     tk_rreq_valid,
    output wire                     tk_rreq_ready,

    input  wire                     rreq_valid,
    input  wire [ID_WIDTH-1:0]      rreq_id,

    // BResp Channel

    (* __emu_model_channel_name = "bresp" *)
    (* __emu_model_channel_direction = "out" *)
    (* __emu_model_channel_depends_on = "breq" *)
    (* __emu_model_channel_payload = "bresp_*" *)
    (* __emu_model_channel_valid = "tk_bresp_valid" *)
    (* __emu_model_channel_ready = "tk_bresp_ready" *)

    output wire                     tk_bresp_valid,
    input  wire                     tk_bresp_ready,

    // RResp Channel

    (* __emu_model_channel_name = "rresp" *)
    (* __emu_model_channel_direction = "out" *)
    (* __emu_model_channel_depends_on = "rreq" *)
    (* __emu_model_channel_payload = "rresp_*" *)
    (* __emu_model_channel_valid = "tk_rresp_valid" *)
    (* __emu_model_channel_ready = "tk_rresp_ready" *)

    output wire                     tk_rresp_valid,
    input  wire                     tk_rresp_ready,

    output wire [DATA_WIDTH-1:0]    rresp_data,
    output wire                     rresp_last,

    ///// INTERFACE host_axi BEGIN /////

    (* __emu_extern_intf_addr_pages = PF_COUNT *)
    (* __emu_extern_intf = "host_axi" *)
    output wire                     host_axi_awvalid,
    (* __emu_extern_intf = "host_axi" *)
    input  wire                     host_axi_awready,
    (* __emu_extern_intf = "host_axi", __emu_extern_intf_type = "address" *)
    output wire [ADDR_WIDTH-1:0]    host_axi_awaddr,
    (* __emu_extern_intf = "host_axi" *)
    output wire [ID_WIDTH-1:0]      host_axi_awid,
    (* __emu_extern_intf = "host_axi" *)
    output wire [7:0]               host_axi_awlen,
    (* __emu_extern_intf = "host_axi" *)
    output wire [2:0]               host_axi_awsize,
    (* __emu_extern_intf = "host_axi" *)
    output wire [1:0]               host_axi_awburst,
    (* __emu_extern_intf = "host_axi" *)
    output wire [0:0]               host_axi_awlock,
    (* __emu_extern_intf = "host_axi" *)
    output wire [3:0]               host_axi_awcache,
    (* __emu_extern_intf = "host_axi" *)
    output wire [2:0]               host_axi_awprot,
    (* __emu_extern_intf = "host_axi" *)
    output wire [3:0]               host_axi_awqos,
    (* __emu_extern_intf = "host_axi" *)
    output wire [3:0]               host_axi_awregion,
    (* __emu_extern_intf = "host_axi" *)
    output wire                     host_axi_wvalid,
    (* __emu_extern_intf = "host_axi" *)
    input  wire                     host_axi_wready,
    (* __emu_extern_intf = "host_axi" *)
    output wire [DATA_WIDTH-1:0]    host_axi_wdata,
    (* __emu_extern_intf = "host_axi" *)
    output wire [DATA_WIDTH/8-1:0]  host_axi_wstrb,
    (* __emu_extern_intf = "host_axi" *)
    output wire                     host_axi_wlast,
    (* __emu_extern_intf = "host_axi" *)
    input  wire                     host_axi_bvalid,
    (* __emu_extern_intf = "host_axi" *)
    output wire                     host_axi_bready,
    (* __emu_extern_intf = "host_axi" *)
    input  wire [1:0]               host_axi_bresp,
    (* __emu_extern_intf = "host_axi" *)
    input  wire [ID_WIDTH-1:0]      host_axi_bid,
    (* __emu_extern_intf = "host_axi" *)
    output wire                     host_axi_arvalid,
    (* __emu_extern_intf = "host_axi" *)
    input  wire                     host_axi_arready,
    (* __emu_extern_intf = "host_axi", __emu_extern_intf_type = "address" *)
    output wire [ADDR_WIDTH-1:0]    host_axi_araddr,
    (* __emu_extern_intf = "host_axi" *)
    output wire [ID_WIDTH-1:0]      host_axi_arid,
    (* __emu_extern_intf = "host_axi" *)
    output wire [7:0]               host_axi_arlen,
    (* __emu_extern_intf = "host_axi" *)
    output wire [2:0]               host_axi_arsize,
    (* __emu_extern_intf = "host_axi" *)
    output wire [1:0]               host_axi_arburst,
    (* __emu_extern_intf = "host_axi" *)
    output wire [0:0]               host_axi_arlock,
    (* __emu_extern_intf = "host_axi" *)
    output wire [3:0]               host_axi_arcache,
    (* __emu_extern_intf = "host_axi" *)
    output wire [2:0]               host_axi_arprot,
    (* __emu_extern_intf = "host_axi" *)
    output wire [3:0]               host_axi_arqos,
    (* __emu_extern_intf = "host_axi" *)
    output wire [3:0]               host_axi_arregion,
    (* __emu_extern_intf = "host_axi" *)
    input  wire                     host_axi_rvalid,
    (* __emu_extern_intf = "host_axi" *)
    output wire                     host_axi_rready,
    (* __emu_extern_intf = "host_axi" *)
    input  wire [DATA_WIDTH-1:0]    host_axi_rdata,
    (* __emu_extern_intf = "host_axi" *)
    input  wire [1:0]               host_axi_rresp,
    (* __emu_extern_intf = "host_axi" *)
    input  wire [ID_WIDTH-1:0]      host_axi_rid,
    (* __emu_extern_intf = "host_axi" *)
    input  wire                     host_axi_rlast,

    ///// INTERFACE host_axi END /////

    (* __emu_model_common_port = "run_mode" *)
    input  wire                     run_mode,
    (* __emu_model_common_port = "scan_mode" *)
    input  wire                     scan_mode,
    (* __emu_model_common_port = "idle" *)
    output wire                     idle

);

    localparam  W_FIFO_DEPTH    = 256;
    localparam  B_FIFO_DEPTH    = 1;
    localparam  R_FIFO_DEPTH    = 256;

    `AXI4_CUSTOM_A_WIRE(frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(frontend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    // Channel token handshake logic

    wire tk_rst_fire = tk_rst_valid && tk_rst_ready;
    wire tk_areq_fire = tk_areq_valid && tk_areq_ready;
    wire tk_wreq_fire = tk_wreq_valid && tk_wreq_ready;
    wire tk_breq_fire = tk_breq_valid && tk_breq_ready;
    wire tk_rreq_fire = tk_rreq_valid && tk_rreq_ready;
    wire tk_bresp_fire = tk_bresp_valid && tk_bresp_ready;
    wire tk_rresp_fire = tk_rresp_valid && tk_rresp_ready;

    // areq channel

    assign frontend_avalid  = tk_areq_valid && areq_valid;
    assign frontend_awrite  = areq_write;
    assign frontend_aaddr   = areq_addr;
    assign frontend_aid     = areq_id;
    assign frontend_alen    = areq_len;
    assign frontend_asize   = areq_size;
    assign frontend_aburst  = areq_burst;
    assign tk_areq_ready    = frontend_aready || !areq_valid;

    // wreq channel

    assign frontend_wvalid  = tk_wreq_valid && wreq_valid;
    assign frontend_wdata   = wreq_data;
    assign frontend_wstrb   = wreq_strb;
    assign frontend_wlast   = wreq_last;
    assign tk_wreq_ready    = frontend_wready || !wreq_valid;

    // breq & bresp channel

    wire bresp_empty_valid = 1'b1;
    wire bresp_empty_ready;

    wire bresp_prejoin_valid;
    wire bresp_prejoin_ready;

    emulib_ready_valid_mux #(
        .NUM_I      (2),
        .NUM_O      (1),
        .DATA_WIDTH (1)
    ) bresp_mux (
        .i_valid    ({frontend_bvalid, bresp_empty_valid}),
        .i_ready    ({frontend_bready, bresp_empty_ready}),
        .i_data     (2'b00/*unused*/),
        .i_sel      ({breq_valid, !breq_valid}),
        .o_valid    (bresp_prejoin_valid),
        .o_ready    (bresp_prejoin_ready),
        .o_data     (),
        .o_sel      (1'b1)
    );

    emulib_ready_valid_join #(
        .BRANCHES   (2)
    ) bresp_join (
        .i_valid    ({bresp_prejoin_valid, tk_breq_valid}),
        .i_ready    ({bresp_prejoin_ready, tk_breq_ready}),
        .o_valid    (tk_bresp_valid),
        .o_ready    (tk_bresp_ready)
    );

    // rreq & rresp channel

    wire rresp_empty_valid = 1'b1;
    wire rresp_empty_ready;

    wire rresp_prejoin_valid;
    wire rresp_prejoin_ready;

    emulib_ready_valid_mux #(
        .NUM_I      (2),
        .NUM_O      (1),
        .DATA_WIDTH (DATA_WIDTH+1)
    ) rresp_mux (
        .i_valid    ({frontend_rvalid, rresp_empty_valid}),
        .i_ready    ({frontend_rready, rresp_empty_ready}),
        .i_data     ({{frontend_rdata, frontend_rlast}, {DATA_WIDTH+1{1'b0}}}),
        .i_sel      ({rreq_valid, !rreq_valid}),
        .o_valid    (rresp_prejoin_valid),
        .o_ready    (rresp_prejoin_ready),
        .o_data     ({rresp_data, rresp_last}),
        .o_sel      (1'b1)
    );

    emulib_ready_valid_join #(
        .BRANCHES   (2)
    ) rresp_join (
        .i_valid    ({rresp_prejoin_valid, tk_rreq_valid}),
        .i_ready    ({rresp_prejoin_ready, tk_rreq_ready}),
        .o_valid    (tk_rresp_valid),
        .o_ready    (tk_rresp_ready)
    );

    // FIFOs for A, W, B, R

    wire fifo_clear;

    `AXI4_CUSTOM_A_WIRE(sched, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_W_WIRE(sched, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_B_WIRE(sched, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_R_WIRE(sched, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    wire [$clog2(MAX_INFLIGHT):0] a_fifo_count;

    emulib_ready_valid_fifo #(
        .WIDTH      (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (MAX_INFLIGHT)
    ) a_fifo (
        .clk        (mdl_clk),
        .rst        (mdl_rst || fifo_clear),
        .ivalid     (frontend_avalid),
        .iready     (frontend_aready),
        .idata      (`AXI4_CUSTOM_A_PAYLOAD(frontend)),
        .ovalid     (sched_avalid),
        .oready     (sched_aready),
        .odata      (`AXI4_CUSTOM_A_PAYLOAD(sched)),
        .count      (a_fifo_count)
    );

    wire [$clog2(W_FIFO_DEPTH):0] w_fifo_count;

    emulib_ready_valid_fifo #(
        .WIDTH      (`AXI4_CUSTOM_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (W_FIFO_DEPTH)
    ) w_fifo (
        .clk        (mdl_clk),
        .rst        (mdl_rst || fifo_clear),
        .ivalid     (frontend_wvalid),
        .iready     (frontend_wready),
        .idata      (`AXI4_CUSTOM_W_PAYLOAD(frontend)),
        .ovalid     (sched_wvalid),
        .oready     (sched_wready),
        .odata      (`AXI4_CUSTOM_W_PAYLOAD(sched)),
        .count      (w_fifo_count)
    );

    wire [$clog2(B_FIFO_DEPTH):0] b_fifo_count;

    emulib_ready_valid_fifo #(
        .WIDTH      (`AXI4_CUSTOM_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (B_FIFO_DEPTH)
    ) b_fifo (
        .clk        (mdl_clk),
        .rst        (mdl_rst || fifo_clear),
        .ivalid     (sched_bvalid),
        .iready     (sched_bready),
        .idata      (`AXI4_CUSTOM_B_PAYLOAD(sched)),
        .ovalid     (frontend_bvalid),
        .oready     (frontend_bready),
        .odata      (`AXI4_CUSTOM_B_PAYLOAD(frontend)),
        .count      (b_fifo_count)
    );

    wire [$clog2(R_FIFO_DEPTH):0] r_fifo_count;

    emulib_ready_valid_fifo #(
        .WIDTH      (`AXI4_CUSTOM_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)),
        .DEPTH      (R_FIFO_DEPTH)
    ) r_fifo (
        .clk        (mdl_clk),
        .rst        (mdl_rst || fifo_clear),
        .ivalid     (sched_rvalid),
        .iready     (sched_rready),
        .idata      (`AXI4_CUSTOM_R_PAYLOAD(sched)),
        .ovalid     (frontend_rvalid),
        .oready     (frontend_rready),
        .odata      (`AXI4_CUSTOM_R_PAYLOAD(frontend)),
        .count      (r_fifo_count)
    );

    // Gate A & W requests

    wire sched_enable_a, sched_enable_w;

    wire gated_sched_avalid, gated_sched_aready;
    wire gated_sched_wvalid, gated_sched_wready;

    emulib_ready_valid_gate #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_sched_a (
        .i_valid    (sched_avalid),
        .i_ready    (sched_aready),
        .o_valid    (gated_sched_avalid),
        .o_ready    (gated_sched_aready),
        .enable     (sched_enable_a)
    );

    emulib_ready_valid_gate #(
        .DECOUPLE_S (1),
        .DECOUPLE_M (1)
    ) gate_sched_w (
        .i_valid    (sched_wvalid),
        .i_ready    (sched_wready),
        .o_valid    (gated_sched_wvalid),
        .o_ready    (gated_sched_wready),
        .enable     (sched_enable_w)
    );

    // Route A to AW/AR

    `AXI4_CUSTOM_A_WIRE(routed_aw, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(routed_ar, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_I      (1),
        .NUM_O      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) a_router (
        .i_valid    (gated_sched_avalid),
        .i_ready    (gated_sched_aready),
        .i_data     (`AXI4_CUSTOM_A_PAYLOAD(sched)),
        .i_sel      (1'b1),
        .o_valid    ({routed_aw_avalid, routed_ar_avalid}),
        .o_ready    ({routed_aw_aready, routed_ar_aready}),
        .o_data     ({`AXI4_CUSTOM_A_PAYLOAD(routed_aw), `AXI4_CUSTOM_A_PAYLOAD(routed_ar)}),
        .o_sel      ({sched_awrite, ~sched_awrite})
    );

    assign host_axi_awvalid     = routed_aw_avalid && !scan_mode;
    assign routed_aw_aready     = host_axi_awready && !scan_mode;
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

    assign host_axi_wvalid      = gated_sched_wvalid && !scan_mode;
    assign gated_sched_wready   = host_axi_wready && !scan_mode;
    assign `AXI4_CUSTOM_W_PAYLOAD(host_axi) = `AXI4_CUSTOM_W_PAYLOAD(sched);

    assign sched_bvalid         = host_axi_bvalid && !scan_mode;
    assign host_axi_bready      = sched_bready && !scan_mode;
    assign `AXI4_CUSTOM_B_PAYLOAD(sched) = `AXI4_CUSTOM_B_PAYLOAD(host_axi);

    assign host_axi_arvalid     = routed_ar_avalid && !scan_mode;
    assign routed_ar_aready     = host_axi_arready && !scan_mode;
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

    assign sched_rvalid         = host_axi_rvalid && !scan_mode;
    assign host_axi_rready      = sched_rready && !scan_mode;
    assign `AXI4_CUSTOM_R_PAYLOAD(sched) = `AXI4_CUSTOM_R_PAYLOAD(host_axi);

    // Scheduler & responser FSMs

    wire sched_afire    = sched_avalid && sched_aready;
    wire sched_wfire    = sched_wvalid && sched_wready;
    wire host_axi_bfire = host_axi_bvalid && host_axi_bready;
    wire host_axi_rfire = host_axi_rvalid && host_axi_rready;

    localparam [2:0]
        SCHED_IDLE  = 3'd0,
        SCHED_DO_A  = 3'd1,
        SCHED_DO_W  = 3'd2,
        SCHED_DO_R  = 3'd3,
        SCHED_DO_B  = 3'd4;

    reg [2:0] sched_state, sched_state_next;

    wire sched_ok_to_ar = sched_avalid && !sched_awrite && r_fifo_count == 0;
    wire sched_ok_to_aw = sched_avalid && sched_awrite && w_fifo_count > sched_alen && b_fifo_count == 0;
    wire sched_ok_to_a = (sched_ok_to_ar || sched_ok_to_aw) && run_mode;

    always @(posedge mdl_clk)
        if (mdl_rst)
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

    assign idle = sched_state == SCHED_IDLE;

    // Reset handler

    reset_token_handler resetter (
        .mdl_clk        (mdl_clk),
        .mdl_rst        (mdl_rst),
        .tk_rst_valid   (tk_rst_valid),
        .tk_rst_ready   (tk_rst_ready),
        .tk_rst         (rst),
        .allow_rst      (idle),
        .rst_out        (fifo_clear)
    );

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

    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (sched_state != sched_state_next) begin
                $display("[%0d ns] %m: sched_state %0s -> %0s", $time,
                    sched_state_name(sched_state),
                    sched_state_name(sched_state_next));
            end
        end
    end

`endif

endmodule

`default_nettype wire
