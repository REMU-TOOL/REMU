module latency_cfg (
    output wire [15:0]  r_delay_conn,
    output wire [15:0]  w_delay_conn,

    (* remu_signal, remu_signal_init = 16'd1 *)
    input  wire [15:0]  r_delay,
    (* remu_signal, remu_signal_init = 16'd1 *)
    input  wire [15:0]  w_delay
);

    assign r_delay_conn = r_delay;
    assign w_delay_conn = w_delay;

endmodule

module latency_pipe #(
    parameter   ADDR_WIDTH      = 32,
    parameter   ID_WIDTH        = 4,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8
)(

    input  wire                     clk,
    input  wire                     rst,

    input  wire                     arvalid,
    output wire                     arready,
    input  wire [ID_WIDTH-1:0]      arid,
    input  wire [ADDR_WIDTH-1:0]    araddr,
    input  wire [7:0]               arlen,
    input  wire [2:0]               arsize,
    input  wire [1:0]               arburst,

    input  wire                     awvalid,
    output wire                     awready,
    input  wire [ID_WIDTH-1:0]      awid,
    input  wire [ADDR_WIDTH-1:0]    awaddr,
    input  wire [7:0]               awlen,
    input  wire [2:0]               awsize,
    input  wire [1:0]               awburst,

    input  wire                     wvalid,
    output wire                     wready,
    input  wire                     wlast,

    output wire                     bvalid,
    input  wire                     bready,
    output wire [ID_WIDTH-1:0]      bid,

    output wire                     rvalid,
    input  wire                     rready,
    output wire [ID_WIDTH-1:0]      rid

);

    ///// params /////

    wire [15:0] r_delay, w_delay;

   latency_cfg cfg (
        .r_delay_conn   (r_delay),
        .w_delay_conn   (w_delay)
    );

    ///// read timing /////

    localparam R_TS_LEN = $clog2(MAX_R_INFLIGHT)*16;

    // time stamp register
    reg [R_TS_LEN-1:0] r_ts_reg;

    always @(posedge clk) begin
        if (rst)
            r_ts_reg <= 0;
        else
            r_ts_reg <= r_ts_reg + 1;
    end

    // the time stamp to response
    wire [R_TS_LEN-1:0] next_rresp_ts = r_ts_reg + r_delay;

    wire r_wait_q_o_valid;
    wire r_wait_q_o_ready;
    wire [R_TS_LEN-1:0] r_wait_q_o_ts;
    wire [ID_WIDTH-1:0] r_wait_q_o_id;
    wire [7:0] r_wait_q_o_len;

    emulib_ready_valid_fifo #(
        .WIDTH      (R_TS_LEN+ID_WIDTH+8),
        .DEPTH      (MAX_R_INFLIGHT),
        .FAST_READ  (1)
    ) r_wait_q (
        .clk        (clk),
        .rst        (rst),
        .ivalid     (arvalid),
        .iready     (arready),
        .idata      ({next_rresp_ts, arid, arlen}),
        .ovalid     (r_wait_q_o_valid),
        .oready     (r_wait_q_o_ready),
        .odata      ({r_wait_q_o_ts, r_wait_q_o_id, r_wait_q_o_len})
    );

    wire r_delay_finish = r_wait_q_o_ts == r_ts_reg;

    wire r_complete_q_i_valid;
    wire r_complete_q_i_ready;

    assign r_complete_q_i_valid = r_wait_q_o_valid && r_delay_finish;
    assign r_wait_q_o_ready = r_complete_q_i_ready && r_delay_finish;

    wire r_complete_q_o_valid;
    wire r_complete_q_o_ready;
    wire [ID_WIDTH-1:0] r_complete_q_o_id;
    wire [7:0] r_complete_q_o_len;

    emulib_ready_valid_fifo #(
        .WIDTH      (ID_WIDTH+8),
        .DEPTH      (MAX_R_INFLIGHT),
        .FAST_READ  (1)
    ) r_complete_q (
        .clk        (clk),
        .rst        (rst),
        .ivalid     (r_complete_q_i_valid),
        .iready     (r_complete_q_i_ready),
        .idata      ({r_wait_q_o_id, r_wait_q_o_len}),
        .ovalid     (r_complete_q_o_valid),
        .oready     (r_complete_q_o_ready),
        .odata      ({r_complete_q_o_id, r_complete_q_o_len})
    );

    // generate burst read response

    reg [7:0] rcnt;

    always @(posedge clk) begin
        if (rst) begin
            rcnt <= 0;
        end
        else if (r_complete_q_o_valid && r_complete_q_o_ready) begin
            rcnt <= 0;
        end
        else if (rvalid && rready) begin
            rcnt <= rcnt + 1;
        end
    end

    assign rvalid = r_complete_q_o_valid;
    assign rid = r_complete_q_o_id;
    assign r_complete_q_o_ready = rready && rcnt == r_complete_q_o_len;

    ///// write timing /////

    localparam W_TS_LEN = $clog2(MAX_W_INFLIGHT)*16;

    // time stamp register
    reg [W_TS_LEN-1:0] w_ts_reg;

    always @(posedge clk) begin
        if (rst)
            w_ts_reg <= 0;
        else
            w_ts_reg <= w_ts_reg + 1;
    end

    // the time stamp to response
    wire [W_TS_LEN-1:0] next_wresp_ts = w_ts_reg + w_delay;

    reg wreq_active;
    reg [ID_WIDTH-1:0] wreq_id;

    always @(posedge clk) begin
        if (rst) begin
            wreq_active <= 0;
            wreq_id <= 0;
        end
        else if (awvalid && awready) begin
            wreq_active <= 1;
            wreq_id <= awid;
        end
        else if (wvalid && wready && wlast) begin
            wreq_active <= 0;
        end
    end

    assign awready = !wreq_active;

    wire w_wait_q_i_valid;
    wire w_wait_q_i_ready;

    wire w_wait_q_o_valid;
    wire w_wait_q_o_ready;
    wire [W_TS_LEN-1:0] w_wait_q_o_ts;
    wire [ID_WIDTH-1:0] w_wait_q_o_id;

    emulib_ready_valid_fifo #(
        .WIDTH      (W_TS_LEN+ID_WIDTH),
        .DEPTH      (MAX_W_INFLIGHT),
        .FAST_READ  (1)
    ) w_wait_q (
        .clk        (clk),
        .rst        (rst),
        .ivalid     (w_wait_q_i_valid),
        .iready     (w_wait_q_i_ready),
        .idata      ({next_wresp_ts, wreq_id}),
        .ovalid     (w_wait_q_o_valid),
        .oready     (w_wait_q_o_ready),
        .odata      ({w_wait_q_o_ts, w_wait_q_o_id})
    );

    assign w_wait_q_i_valid = wvalid && wlast && wreq_active;
    assign wready = w_wait_q_i_ready && wreq_active;

    wire w_delay_finish = w_wait_q_o_ts == w_ts_reg;

    wire w_complete_q_i_valid;
    wire w_complete_q_i_ready;

    assign w_complete_q_i_valid = w_wait_q_o_valid && w_delay_finish;
    assign w_wait_q_o_ready = w_complete_q_i_ready && w_delay_finish;

    emulib_ready_valid_fifo #(
        .WIDTH      (ID_WIDTH),
        .DEPTH      (MAX_W_INFLIGHT),
        .FAST_READ  (1)
    ) w_complete_q (
        .clk        (clk),
        .rst        (rst),
        .ivalid     (w_complete_q_i_valid),
        .iready     (w_complete_q_i_ready),
        .idata      (w_wait_q_o_id),
        .ovalid     (bvalid),
        .oready     (bready),
        .odata      (bid)
    );

endmodule