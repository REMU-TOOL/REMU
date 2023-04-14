`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

(* __emu_model_imp *)
module emulib_rammodel_backend #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MEM_SIZE        = 64'h10000000,
    // Note: Max inflight parameters only decide FIFO depths
    // Tthe tracker is responsible to throttle requests before the limit is exceeded
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8
)(

    (* __emu_common_port = "mdl_clk" *)
    input  wire                     mdl_clk,
    (* __emu_common_port = "mdl_rst" *)
    input  wire                     mdl_rst,

    input  wire                     clk,

    // Reset Channel

    (* __emu_channel_name = "rst"*)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "rst" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_rst_valid" *)
    (* __emu_channel_ready = "tk_rst_ready" *)

    input  wire                     tk_rst_valid,
    output wire                     tk_rst_ready,

    input  wire                     rst,

    // ARReq Channel

    (* __emu_channel_name = "arreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "arreq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_arreq_valid" *)
    (* __emu_channel_ready = "tk_arreq_ready" *)

    input  wire                     tk_arreq_valid,
    output wire                     tk_arreq_ready,

    input  wire                     arreq_valid,
    input  wire [ID_WIDTH-1:0]      arreq_id,
    input  wire [ADDR_WIDTH-1:0]    arreq_addr,
    input  wire [7:0]               arreq_len,
    input  wire [2:0]               arreq_size,
    input  wire [1:0]               arreq_burst,

    // AWReq Channel

    (* __emu_channel_name = "awreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "awreq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_awreq_valid" *)
    (* __emu_channel_ready = "tk_awreq_ready" *)

    input  wire                     tk_awreq_valid,
    output wire                     tk_awreq_ready,

    input  wire                     awreq_valid,
    input  wire [ID_WIDTH-1:0]      awreq_id,
    input  wire [ADDR_WIDTH-1:0]    awreq_addr,
    input  wire [7:0]               awreq_len,
    input  wire [2:0]               awreq_size,
    input  wire [1:0]               awreq_burst,

    // WReq Channel

    (* __emu_channel_name = "wreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "areq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_wreq_valid" *)
    (* __emu_channel_ready = "tk_wreq_ready" *)

    input  wire                     tk_wreq_valid,
    output wire                     tk_wreq_ready,

    input  wire                     wreq_valid,
    input  wire [DATA_WIDTH-1:0]    wreq_data,
    input  wire [DATA_WIDTH/8-1:0]  wreq_strb,
    input  wire                     wreq_last,

    // BReq Channel

    (* __emu_channel_name = "breq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "breq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_breq_valid" *)
    (* __emu_channel_ready = "tk_breq_ready" *)

    input  wire                     tk_breq_valid,
    output wire                     tk_breq_ready,

    input  wire                     breq_valid,
    input  wire [ID_WIDTH-1:0]      breq_id,

    // RReq Channel

    (* __emu_channel_name = "rreq" *)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "rreq_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_rreq_valid" *)
    (* __emu_channel_ready = "tk_rreq_ready" *)

    input  wire                     tk_rreq_valid,
    output wire                     tk_rreq_ready,

    input  wire                     rreq_valid,
    input  wire [ID_WIDTH-1:0]      rreq_id,

    // BResp Channel

    (* __emu_channel_name = "bresp" *)
    (* __emu_channel_direction = "out" *)
    (* __emu_channel_depends_on = "breq" *)
    (* __emu_channel_payload = "bresp_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_bresp_valid" *)
    (* __emu_channel_ready = "tk_bresp_ready" *)

    output wire                     tk_bresp_valid,
    input  wire                     tk_bresp_ready,

    // RResp Channel

    (* __emu_channel_name = "rresp" *)
    (* __emu_channel_direction = "out" *)
    (* __emu_channel_depends_on = "rreq" *)
    (* __emu_channel_payload = "rresp_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_rresp_valid" *)
    (* __emu_channel_ready = "tk_rresp_ready" *)

    output wire                     tk_rresp_valid,
    input  wire                     tk_rresp_ready,

    output wire [DATA_WIDTH-1:0]    rresp_data,
    output wire                     rresp_last,

    (* __emu_axi_name = "host_axi" *)
    (* __emu_axi_type = "axi4" *)
    (* __emu_axi_size = MEM_SIZE *)
    `AXI4_MASTER_IF_NO_ID           (host_axi,      ADDR_WIDTH, DATA_WIDTH),

    (* __emu_common_port = "run_mode" *)
    input  wire                     run_mode,
    (* __emu_common_port = "scan_mode" *)
    input  wire                     scan_mode,
    (* __emu_common_port = "idle" *)
    output wire                     idle

);

    localparam  A_PAYLOAD_LEN   = `AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    localparam  W_PAYLOAD_LEN   = `AXI4_CUSTOM_W_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    localparam  B_PAYLOAD_LEN   = `AXI4_CUSTOM_B_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    localparam  R_PAYLOAD_LEN   = `AXI4_CUSTOM_R_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    localparam  A_ISSUE_Q_DEPTH = MAX_R_INFLIGHT + MAX_W_INFLIGHT;
    localparam  W_ISSUE_Q_DEPTH = 256 * MAX_W_INFLIGHT;
    localparam  R_ROQ_DEPTH     = 256 * MAX_R_INFLIGHT;
    localparam  B_ROQ_DEPTH     = MAX_W_INFLIGHT;
    localparam  ID_NUM          = 2 ** ID_WIDTH;

    genvar gen_i;
    integer loop_i;

    wire soft_rst;
    wire fifo_rst = mdl_rst || soft_rst;

    //// ARReq/AWReq arbitration ////

    `AXI4_CUSTOM_A_WIRE(arb_i_ar,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(arb_i_aw,   ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_CUSTOM_A_WIRE(arb_o,      ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    assign arb_i_ar_avalid  = tk_arreq_valid && arreq_valid;
    assign arb_i_ar_awrite  = 1'b0;
    assign arb_i_ar_aaddr   = arreq_addr;
    assign arb_i_ar_aid     = arreq_id;
    assign arb_i_ar_alen    = arreq_len;
    assign arb_i_ar_asize   = arreq_size;
    assign arb_i_ar_aburst  = arreq_burst;
    assign tk_arreq_ready   = arb_i_ar_aready || !arreq_valid;

    assign arb_i_aw_avalid  = tk_awreq_valid && awreq_valid;
    assign arb_i_aw_awrite  = 1'b1;
    assign arb_i_aw_aaddr   = awreq_addr;
    assign arb_i_aw_aid     = awreq_id;
    assign arb_i_aw_alen    = awreq_len;
    assign arb_i_aw_asize   = awreq_size;
    assign arb_i_aw_aburst  = awreq_burst;
    assign tk_awreq_ready   = arb_i_aw_aready || !awreq_valid;

    emulib_ready_valid_arbiter #(
        .NUM_I      (2),
        .DATA_WIDTH (A_PAYLOAD_LEN)
    ) aw_ar_arb (
        .i_valid    ({arb_i_aw_avalid, arb_i_ar_avalid}),
        .i_ready    ({arb_i_aw_aready, arb_i_ar_aready}),
        .i_data     ({`AXI4_CUSTOM_A_PAYLOAD(arb_i_aw), `AXI4_CUSTOM_A_PAYLOAD(arb_i_ar)}),
        .o_valid    (arb_o_avalid),
        .o_ready    (arb_o_aready),
        .o_data     (`AXI4_CUSTOM_A_PAYLOAD(arb_o)),
        .o_sel      ()
    );

`ifdef RAMMODEL_BACKEND_DEBUG
    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (arb_o_avalid && arb_o_aready) begin
                $display("[%d ns] AR/AW arbitrated: %s ID %h ADDR %h LEN %h",
                    $time,
                    arb_o_awrite ? "WRITE" : "READ",
                    arb_o_aid,
                    arb_o_aaddr,
                    arb_o_alen);
            end
        end
    end
`endif

    //// A issue queue ////

    `AXI4_CUSTOM_A_WIRE(pre_issue, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_fifo #(
        .WIDTH      (A_PAYLOAD_LEN),
        .DEPTH      (A_ISSUE_Q_DEPTH)
    ) a_issue_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (arb_o_avalid),
        .iready     (arb_o_aready),
        .idata      (`AXI4_CUSTOM_A_PAYLOAD(arb_o)),
        .ovalid     (pre_issue_avalid),
        .oready     (pre_issue_aready),
        .odata      (`AXI4_CUSTOM_A_PAYLOAD(pre_issue))
    );

`ifdef RAMMODEL_BACKEND_DEBUG
    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (pre_issue_avalid && pre_issue_aready) begin
                $display("[%d ns] A issued: %s ID %h ADDR %h LEN %h",
                    $time,
                    pre_issue_awrite ? "WRITE" : "READ",
                    pre_issue_aid,
                    pre_issue_aaddr,
                    pre_issue_alen);
            end
        end
    end
`endif

    //// W issue queue ////

    `AXI4_CUSTOM_W_WIRE(pre_q, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    assign pre_q_wvalid = tk_wreq_valid && wreq_valid;
    assign pre_q_wdata  = wreq_data;
    assign pre_q_wstrb  = wreq_strb;
    assign pre_q_wlast  = wreq_last;
    assign tk_wreq_ready = pre_q_wready || !wreq_valid;

    `AXI4_CUSTOM_W_WIRE(pre_issue, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_fifo #(
        .WIDTH      (W_PAYLOAD_LEN),
        .DEPTH      (W_ISSUE_Q_DEPTH)
    ) w_issue_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (pre_q_wvalid),
        .iready     (pre_q_wready),
        .idata      (`AXI4_CUSTOM_W_PAYLOAD(pre_q)),
        .ovalid     (pre_issue_wvalid),
        .oready     (pre_issue_wready),
        .odata      (`AXI4_CUSTOM_W_PAYLOAD(pre_issue))
    );

    reg [$clog2(W_ISSUE_Q_DEPTH+1)-1:0] w_stream_count = 0;
    wire w_stream_count_inc = pre_q_wvalid && pre_q_wready && pre_q_wlast;
    wire w_stream_count_dec = pre_issue_wvalid && pre_issue_wready && pre_issue_wlast;

    always @(posedge mdl_clk) begin
        if (fifo_rst)
            w_stream_count <= 0;
        else
            w_stream_count <= w_stream_count + w_stream_count_inc - w_stream_count_dec;
    end

`ifdef RAMMODEL_BACKEND_DEBUG
    reg [7:0] w_issue_seq = 0;
    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (pre_issue_wvalid && pre_issue_wready) begin
                $display("[%d ns] W issued: LAST %h Seq %h",
                    $time,
                    pre_issue_wlast,
                    w_issue_seq);
                w_issue_seq = pre_issue_wlast ? 0 : w_issue_seq + 1;
            end
        end
    end
`endif

    //// Request guard ////

    wire allow_req;

    // issue AW req to host only when all data in the burst are ready
    wire wdata_ok = w_stream_count != 0;

    wire host_afire = host_axi_arvalid && host_axi_arready ||
                      host_axi_awvalid && host_axi_awready;

    wire host_bfire = host_axi_bvalid && host_axi_bready;

    wire host_rfire = host_axi_rvalid && host_axi_rready && host_axi_rlast;

    emulib_rammodel_req_guard #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .ID_WIDTH       (ID_WIDTH)
    ) guard (
        .clk        (mdl_clk),
        .rst        (mdl_rst),
        .awrite     (pre_issue_awrite),
        .aaddr      (pre_issue_aaddr),
        .alen       (pre_issue_alen),
        .asize      (pre_issue_asize),
        .aburst     (pre_issue_aburst),
        .afire      (host_afire),
        .bfire      (host_bfire),
        .rfire      (host_rfire),
        .allow_req  (allow_req)
    );

    //// Issue AR/AW requests to host ////

    wire allow_host_ar = allow_req && !scan_mode;
    wire allow_host_aw = allow_req && wdata_ok && !scan_mode;

    assign host_axi_arvalid     = pre_issue_avalid &&
                                  !pre_issue_awrite &&
                                  allow_host_ar;

    assign host_axi_araddr      = pre_issue_aaddr;
    assign host_axi_arlen       = pre_issue_alen;
    assign host_axi_arsize      = pre_issue_asize;
    assign host_axi_arburst     = pre_issue_aburst;
    assign host_axi_arprot      = 3'b010;
    assign host_axi_arlock      = 1'b0;
    assign host_axi_arcache     = 4'd0;
    assign host_axi_arqos       = 4'd0;
    assign host_axi_arregion    = 4'd0;

    assign host_axi_awvalid     = pre_issue_avalid &&
                                  pre_issue_awrite &&
                                  allow_host_aw;

    assign host_axi_awaddr      = pre_issue_aaddr;
    assign host_axi_awlen       = pre_issue_alen;
    assign host_axi_awsize      = pre_issue_asize;
    assign host_axi_awburst     = pre_issue_aburst;
    assign host_axi_awprot      = 3'b010;
    assign host_axi_awlock      = 1'b0;
    assign host_axi_awcache     = 4'd0;
    assign host_axi_awqos       = 4'd0;
    assign host_axi_awregion    = 4'd0;

    assign pre_issue_aready     = pre_issue_awrite ?
                                  (host_axi_awready && allow_host_aw) :
                                  (host_axi_arready && allow_host_ar);

    //// Issue W requests to host ////

    (* __emu_no_scanchain *)
    reg [$clog2(W_ISSUE_Q_DEPTH+1)-1:0] w_stream_credit = 0;
    wire w_stream_credit_inc = host_axi_awvalid && host_axi_awready;
    wire w_stream_credit_dec = host_axi_wvalid && host_axi_wready && host_axi_wlast;

    always @(posedge mdl_clk) begin
        if (mdl_rst)
            w_stream_credit <= 0;
        else
            w_stream_credit <= w_stream_credit + w_stream_credit_inc - w_stream_credit_dec;
    end

    wire allow_host_w = w_stream_credit >= w_stream_count && !scan_mode;

    assign host_axi_wvalid      = pre_issue_wvalid && allow_host_w;
    assign pre_issue_wready     = host_axi_wready && allow_host_w;
    assign `AXI4_CUSTOM_W_PAYLOAD(host_axi) = `AXI4_CUSTOM_W_PAYLOAD(pre_issue);

    //// RID/BID queues to track host-side in-flight requests ////

    wire rid_q_i_valid = pre_issue_avalid && pre_issue_aready && !pre_issue_awrite;
    wire rid_q_i_ready;
    wire [ID_WIDTH-1:0] rid_q_i_id = pre_issue_aid;

    wire rid_q_o_valid;
    wire rid_q_o_ready;
    wire [ID_WIDTH-1:0] rid_q_o_id;

    (* __emu_no_scanchain *)
    emulib_ready_valid_fifo #(
        .WIDTH      (ID_WIDTH),
        .DEPTH      (MAX_R_INFLIGHT),
        .FAST_READ  (1)
    ) rid_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (rid_q_i_valid),
        .iready     (rid_q_i_ready),
        .idata      (rid_q_i_id),
        .ovalid     (rid_q_o_valid),
        .oready     (rid_q_o_ready),
        .odata      (rid_q_o_id)
    );

    wire bid_q_i_valid = pre_issue_avalid && pre_issue_aready && pre_issue_awrite;
    wire bid_q_i_ready;
    wire [ID_WIDTH-1:0] bid_q_i_id = pre_issue_aid;

    wire bid_q_o_valid;
    wire bid_q_o_ready;
    wire [ID_WIDTH-1:0] bid_q_o_id;

    (* __emu_no_scanchain *)
    emulib_ready_valid_fifo #(
        .WIDTH      (ID_WIDTH),
        .DEPTH      (MAX_W_INFLIGHT),
        .FAST_READ  (1)
    ) bid_q (
        .clk        (mdl_clk),
        .rst        (fifo_rst),
        .ivalid     (bid_q_i_valid),
        .iready     (bid_q_i_ready),
        .idata      (bid_q_i_id),
        .ovalid     (bid_q_o_valid),
        .oready     (bid_q_o_ready),
        .odata      (bid_q_o_id)
    );

`ifdef RAMMODEL_BACKEND_DEBUG
    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (rid_q_i_valid) begin
                if (!rid_q_i_ready) begin
                    $display("[%d ns] RID queue overflow", $time);
                    $fatal;
                end
                $display("[%d ns] RID %h queued",
                    $time,
                    rid_q_i_id);
            end
            if (bid_q_i_valid) begin
                if (!bid_q_i_ready) begin
                    $display("[%d ns] BID queue overflow", $time);
                    $fatal;
                end
                $display("[%d ns] BID %h queued",
                    $time,
                    bid_q_i_id);
            end
        end
    end
`endif

    //// R/B reorder queues ////

    wire [ID_NUM-1:0] r_roq_i_valid;
    wire [ID_NUM-1:0] r_roq_i_ready;
    wire [ID_NUM*R_PAYLOAD_LEN-1:0] r_roq_i_data;

    wire [ID_NUM-1:0] r_roq_o_valid;
    wire [ID_NUM-1:0] r_roq_o_ready;
    wire [ID_NUM*R_PAYLOAD_LEN-1:0] r_roq_o_data;

    for (gen_i=0; gen_i<ID_NUM; gen_i=gen_i+1) begin : r_roq_genblk
        emulib_ready_valid_fifo #(
            .WIDTH      (R_PAYLOAD_LEN),
            .DEPTH      (R_ROQ_DEPTH)
        ) queue (
            .clk        (mdl_clk),
            .rst        (fifo_rst),
            .ivalid     (r_roq_i_valid[gen_i]),
            .iready     (r_roq_i_ready[gen_i]),
            .idata      (r_roq_i_data[gen_i*R_PAYLOAD_LEN+:R_PAYLOAD_LEN]),
            .ovalid     (r_roq_o_valid[gen_i]),
            .oready     (r_roq_o_ready[gen_i]),
            .odata      (r_roq_o_data[gen_i*R_PAYLOAD_LEN+:R_PAYLOAD_LEN])
        );
    end

    wire [ID_NUM-1:0] b_roq_i_valid;
    wire [ID_NUM-1:0] b_roq_i_ready;
    wire [ID_NUM*B_PAYLOAD_LEN-1:0] b_roq_i_data;

    wire [ID_NUM-1:0] b_roq_o_valid;
    wire [ID_NUM-1:0] b_roq_o_ready;
    wire [ID_NUM*B_PAYLOAD_LEN-1:0] b_roq_o_data;

    for (gen_i=0; gen_i<ID_NUM; gen_i=gen_i+1) begin : b_roq_genblk
        emulib_ready_valid_fifo #(
            .WIDTH      (B_PAYLOAD_LEN),
            .DEPTH      (B_ROQ_DEPTH)
        ) queue (
            .clk        (mdl_clk),
            .rst        (fifo_rst),
            .ivalid     (b_roq_i_valid[gen_i]),
            .iready     (b_roq_i_ready[gen_i]),
            .idata      (b_roq_i_data[gen_i*B_PAYLOAD_LEN+:B_PAYLOAD_LEN]),
            .ovalid     (b_roq_o_valid[gen_i]),
            .oready     (b_roq_o_ready[gen_i]),
            .odata      (b_roq_o_data[gen_i*B_PAYLOAD_LEN+:B_PAYLOAD_LEN])
        );
    end

    //// Receive R/B responses from host and demux to ROQs ////

    function [ID_NUM-1:0] id2oh (input [ID_WIDTH-1:0] id);
    begin
        id2oh = {{ID_NUM-1{1'b0}}, 1'b1} << id;
    end
    endfunction

    `AXI4_CUSTOM_R_WIRE(pre_reorder, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    assign pre_reorder_rvalid   = host_axi_rvalid && rid_q_o_valid;
    assign pre_reorder_rdata    = host_axi_rdata;
    assign pre_reorder_rid      = rid_q_o_id;
    assign pre_reorder_rlast    = host_axi_rlast;
    assign host_axi_rready      = pre_reorder_rready && rid_q_o_valid;
    assign rid_q_o_ready        = pre_reorder_rvalid &&
                                  pre_reorder_rready &&
                                  pre_reorder_rlast;

    emulib_ready_valid_mux #(
        .NUM_I      (1),
        .NUM_O      (ID_NUM),
        .DATA_WIDTH (R_PAYLOAD_LEN)
    ) r_roq_demux (
        .i_valid    (pre_reorder_rvalid),
        .i_ready    (pre_reorder_rready),
        .i_data     (`AXI4_CUSTOM_R_PAYLOAD(pre_reorder)),
        .i_sel      (1'b1),
        .o_valid    (r_roq_i_valid),
        .o_ready    (r_roq_i_ready),
        .o_data     (r_roq_i_data),
        .o_sel      (id2oh(pre_reorder_rid))
    );

    `AXI4_CUSTOM_B_WIRE(pre_reorder, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    assign pre_reorder_bvalid   = host_axi_bvalid && bid_q_o_valid;
    assign pre_reorder_bid      = bid_q_o_id;
    assign host_axi_bready      = pre_reorder_bready && bid_q_o_valid;
    assign bid_q_o_ready        = pre_reorder_bvalid &&
                                  pre_reorder_bready;

    emulib_ready_valid_mux #(
        .NUM_I      (1),
        .NUM_O      (ID_NUM),
        .DATA_WIDTH (B_PAYLOAD_LEN)
    ) b_roq_demux (
        .i_valid    (pre_reorder_bvalid),
        .i_ready    (pre_reorder_bready),
        .i_data     (`AXI4_CUSTOM_B_PAYLOAD(pre_reorder)),
        .i_sel      (1'b1),
        .o_valid    (b_roq_i_valid),
        .o_ready    (b_roq_i_ready),
        .o_data     (b_roq_i_data),
        .o_sel      (id2oh(pre_reorder_bid))
    );

`ifdef RAMMODEL_BACKEND_DEBUG
    reg [7:0] r_enq_seq [ID_NUM-1:0];

    initial begin
        for (loop_i=0; loop_i<ID_NUM; loop_i=loop_i+1)
            r_enq_seq[loop_i] = 0;
    end

    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (pre_reorder_rvalid && pre_reorder_rready) begin
                $display("[%d ns] R ROQ enqueue: ID %h LAST %h Seq %h",
                    $time,
                    pre_reorder_rid,
                    pre_reorder_rlast,
                    r_enq_seq[pre_reorder_rid]);
                r_enq_seq[pre_reorder_rid] = pre_reorder_rlast ? 0 :
                    r_enq_seq[pre_reorder_rid] + 1;
                if (!rid_q_o_valid) begin
                    $display("[%d ns] RID queue underflow", $time);
                    $fatal;
                end
            end
            if (pre_reorder_bvalid && pre_reorder_bready) begin
                $display("[%d ns] B ROQ enqueue: ID %h",
                    $time,
                    pre_reorder_bid);
                if (!bid_q_o_valid) begin
                    $display("[%d ns] BID queue underflow", $time);
                    $fatal;
                end
            end
        end
    end
`endif

    //// Receive RReq/BReq from frontend and return RResp/BResp ////

    wire reset_pending = tk_rst_valid && rst;

    // RResp

    `AXI4_CUSTOM_R_WIRE(post_reorder, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_I      (ID_NUM),
        .NUM_O      (1),
        .DATA_WIDTH (R_PAYLOAD_LEN)
    ) r_roq_mux (
        .i_valid    (r_roq_o_valid),
        .i_ready    (r_roq_o_ready),
        .i_data     (r_roq_o_data),
        .i_sel      (id2oh(rreq_id)),
        .o_valid    (post_reorder_rvalid),
        .o_ready    (post_reorder_rready),
        .o_data     (`AXI4_CUSTOM_R_PAYLOAD(post_reorder)),
        .o_sel      (1'b1)
    );

    `AXI4_CUSTOM_R_WIRE(whitehole, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    assign whitehole_rvalid = 1'b1;
    assign whitehole_rdata  = {DATA_WIDTH{1'b0}};
    assign whitehole_rid    = {ID_WIDTH{1'b0}};
    assign whitehole_rlast  = 1'b0;

    wire r_dequeue = rreq_valid && !reset_pending;

    `AXI4_CUSTOM_R_WIRE(prejoin, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_I      (2),
        .NUM_O      (1),
        .DATA_WIDTH (R_PAYLOAD_LEN)
    ) rresp_mux (
        .i_valid    ({whitehole_rvalid, post_reorder_rvalid}),
        .i_ready    ({whitehole_rready, post_reorder_rready}),
        .i_data     ({`AXI4_CUSTOM_R_PAYLOAD(whitehole), `AXI4_CUSTOM_R_PAYLOAD(post_reorder)}),
        .i_sel      ({~r_dequeue, r_dequeue}),
        .o_valid    (prejoin_rvalid),
        .o_ready    (prejoin_rready),
        .o_data     (`AXI4_CUSTOM_R_PAYLOAD(prejoin)),
        .o_sel      (1'b1)
    );

    emulib_ready_valid_join #(.BRANCHES(2)) r_join (
        .i_valid    ({prejoin_rvalid, tk_rreq_valid}),
        .i_ready    ({prejoin_rready, tk_rreq_ready}),
        .o_valid    (tk_rresp_valid),
        .o_ready    (tk_rresp_ready)
    );

    assign rresp_data = prejoin_rdata;
    assign rresp_last = prejoin_rlast;

`ifdef RAMMODEL_BACKEND_DEBUG
    reg [7:0] r_deq_seq [ID_NUM-1:0];

    initial begin
        for (loop_i=0; loop_i<ID_NUM; loop_i=loop_i+1)
            r_deq_seq[loop_i] = 0;
    end

    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (post_reorder_rvalid && post_reorder_rready) begin
                $display("[%d ns] R ROQ dequeue: ID %h LAST %h Seq %h",
                    $time,
                    post_reorder_rid,
                    post_reorder_rlast,
                    r_deq_seq[post_reorder_rid]);
                r_deq_seq[post_reorder_rid] = post_reorder_rlast ? 0 :
                    r_deq_seq[post_reorder_rid] + 1;
            end
        end
    end
`endif

    // BResp

    `AXI4_CUSTOM_B_WIRE(post_reorder, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_I      (ID_NUM),
        .NUM_O      (1),
        .DATA_WIDTH (B_PAYLOAD_LEN)
    ) b_roq_mux (
        .i_valid    (b_roq_o_valid),
        .i_ready    (b_roq_o_ready),
        .i_data     (b_roq_o_data),
        .i_sel      (id2oh(breq_id)),
        .o_valid    (post_reorder_bvalid),
        .o_ready    (post_reorder_bready),
        .o_data     (`AXI4_CUSTOM_B_PAYLOAD(post_reorder)),
        .o_sel      (1'b1)
    );

    `AXI4_CUSTOM_B_WIRE(whitehole, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    assign whitehole_bvalid = 1'b1;
    assign whitehole_bid    = {ID_WIDTH{1'b0}};

    wire b_dequeue = breq_valid && !reset_pending;

    `AXI4_CUSTOM_B_WIRE(prejoin, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_mux #(
        .NUM_I      (2),
        .NUM_O      (1),
        .DATA_WIDTH (B_PAYLOAD_LEN)
    ) bresp_mux (
        .i_valid    ({whitehole_bvalid, post_reorder_bvalid}),
        .i_ready    ({whitehole_bready, post_reorder_bready}),
        .i_data     ({`AXI4_CUSTOM_B_PAYLOAD(whitehole), `AXI4_CUSTOM_B_PAYLOAD(post_reorder)}),
        .i_sel      ({~b_dequeue, b_dequeue}),
        .o_valid    (prejoin_bvalid),
        .o_ready    (prejoin_bready),
        .o_data     (`AXI4_CUSTOM_B_PAYLOAD(prejoin)),
        .o_sel      (1'b1)
    );

    emulib_ready_valid_join #(.BRANCHES(2)) b_join (
        .i_valid    ({prejoin_bvalid, tk_breq_valid}),
        .i_ready    ({prejoin_bready, tk_breq_ready}),
        .o_valid    (tk_bresp_valid),
        .o_ready    (tk_bresp_ready)
    );

`ifdef RAMMODEL_BACKEND_DEBUG
    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (post_reorder_bvalid && post_reorder_bready) begin
                $display("[%d ns] B ROQ dequeue: ID %h",
                    $time,
                    post_reorder_bid);
            end
        end
    end
`endif

    //// Reset handler ////

    (* __emu_no_scanchain *)
    reset_token_handler resetter (
        .mdl_clk        (mdl_clk),
        .mdl_rst        (mdl_rst),
        .tk_rst_valid   (tk_rst_valid),
        .tk_rst_ready   (tk_rst_ready),
        .tk_rst         (rst),
        .allow_rst      (idle),
        .rst_out        (soft_rst)
    );

`ifdef RAMMODEL_BACKEND_DEBUG
    always @(posedge mdl_clk) begin
        if (!mdl_rst) begin
            if (tk_rst_valid && tk_rst_ready && rst) begin
                $display("[%d ns] Reset token active", $time);
            end
        end
    end
`endif

    // The model is idle only if there's no requests ready to be sent or host-side in-flight requests

    assign idle = !host_axi_arvalid &&
                  !host_axi_awvalid &&
                  !rid_q_o_valid &&
                  !bid_q_o_valid;

endmodule
