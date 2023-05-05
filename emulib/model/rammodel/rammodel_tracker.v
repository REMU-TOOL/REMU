`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_tracker #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8
)(

    input  wire                     clk,
    input  wire                     rst,

    `AXI4_AW_SLAVE_IF               (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_W_SLAVE_IF                (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_AR_SLAVE_IF               (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    `AXI4_B_INPUT_IF                (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_R_INPUT_IF                (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)

);

    wire axi_arfire = axi_arvalid && axi_arready;
    wire axi_awfire = axi_awvalid && axi_awready;
    wire axi_wfire = axi_wvalid && axi_wready;
    wire axi_rfire = axi_rvalid && axi_rready;
    wire axi_bfire = axi_bvalid && axi_bready;

    // In-flight read/write request counter

    localparam R_IF_CNT_LEN = $clog2(MAX_R_INFLIGHT + 1);
    localparam W_IF_CNT_LEN = $clog2(MAX_W_INFLIGHT + 1);

    reg [R_IF_CNT_LEN-1:0] r_if_cnt;
    reg [W_IF_CNT_LEN-1:0] w_if_cnt;

    always @(posedge clk)
        if (rst)
            r_if_cnt <= 0;
        else
            r_if_cnt <= r_if_cnt + axi_arfire - (axi_rfire && axi_rlast);

    always @(posedge clk)
        if (rst)
            w_if_cnt <= 0;
        else
            w_if_cnt <= w_if_cnt + axi_awfire - axi_bfire;

    // Workaround: we have to send read when no write in in flight
    // because the backend may not complete a read request if there is an incomplete write (AW sent but W not completely sent)
    // sending AR & AW at the same time is OK because AR has higher arbitration priority in the backend
    assign axi_arready = r_if_cnt != MAX_R_INFLIGHT && w_if_cnt == 0;
    assign axi_awready = w_if_cnt != MAX_W_INFLIGHT;

    // AWLEN FIFO

    wire awlen_q_rinc;
    wire awlen_q_rempty;
    wire [7:0] awlen_q_rdata;

    emulib_fifo #(
        .WIDTH      (8),
        .DEPTH      (MAX_W_INFLIGHT),
        .FAST_READ  (1)
    ) awlen_q (
        .clk        (clk),
        .rst        (rst),
        .winc       (axi_awfire),
        .wfull      (),
        .wdata      (axi_awlen),
        .rinc       (awlen_q_rinc),
        .rempty     (awlen_q_rempty),
        .rdata      (awlen_q_rdata)
    );

    assign axi_wready = !awlen_q_rempty;
    assign awlen_q_rinc = axi_wfire && axi_wlast;

    reg [8:0] wcnt = 9'd0;

    always @(posedge clk) begin
        if (rst)
            wcnt <= 9'd0;
        else if (axi_wfire)
            wcnt <= axi_wlast ? 9'd0 : wcnt + 9'd1;
    end

    (* remu_trigger *)
    wire w_count_overflow = wcnt[8];

    (* remu_trigger *)
    reg w_pos_check_failed = 1'b0;

    always @(posedge clk)
        w_pos_check_failed <= axi_wfire && axi_wlast && (awlen_q_rdata != wcnt);

endmodule
