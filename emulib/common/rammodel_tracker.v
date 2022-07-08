`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_tracker #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MAX_INFLIGHT    = 8
)(

    input  wire                     clk,
    input  wire                     rst,

    `AXI4_AW_SLAVE_IF               (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_W_SLAVE_IF                (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_AR_SLAVE_IF               (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    `AXI4_B_SLAVE_IF                (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_R_SLAVE_IF                (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

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
    output wire                     wreq_last

);

    // AW/AR arbitration

    `AXI4_CUSTOM_A_WIRE(arb, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_arb #(
        .NUM_I      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) aw_ar_arb (
        .i_valid    ({axi_awvalid, axi_arvalid}),
        .i_ready    ({axi_awready, axi_arready}),
        .i_data     ({`AXI4_CUSTOM_A_PAYLOAD_FROM_AW(axi), `AXI4_CUSTOM_A_PAYLOAD_FROM_AR(axi)}),
        .o_valid    (arb_avalid),
        .o_ready    (arb_aready),
        .o_data     (`AXI4_CUSTOM_A_PAYLOAD(arb)),
        .o_sel      ()
    );

    // In-flight counter

    localparam IF_CNT_LEN = $clog2(MAX_INFLIGHT) + 1;

    reg [IF_CNT_LEN-1:0] if_cnt, if_cnt_next;

    always @(posedge clk)
        if (rst)
            if_cnt <= 0;
        else
            if_cnt <= if_cnt_next;

    always @* begin
        if_cnt_next = if_cnt;
        if (arb_avalid && arb_aready)
            if_cnt_next = if_cnt_next + 1;
        if (axi_bvalid && axi_bready)
            if_cnt_next = if_cnt_next - 1;
        if (axi_rvalid && axi_rready && axi_rlast)
            if_cnt_next = if_cnt_next - 1;
    end

    wire if_full = if_cnt == MAX_INFLIGHT;

    // AW counter

    reg [IF_CNT_LEN-1:0] aw_cnt, aw_cnt_next;

    always @(posedge clk)
        if (rst)
            aw_cnt <= 0;
        else
            aw_cnt <= aw_cnt_next;

    always @* begin
        aw_cnt_next = aw_cnt;
        if (axi_awvalid && axi_awready)
            aw_cnt_next = aw_cnt_next + 1;
        if (axi_wvalid && axi_wready && axi_wlast)
            aw_cnt_next = aw_cnt_next - 1;
    end

    wire aw_empty = aw_cnt == 0;

    // Apply restrictions

    assign areq_valid   = arb_avalid && arb_aready;
    assign areq_write   = arb_awrite;
    assign areq_id      = arb_aid;
    assign areq_addr    = arb_aaddr;
    assign areq_len     = arb_alen;
    assign areq_size    = arb_asize;
    assign areq_burst   = arb_aburst;
    assign arb_aready   = !if_full;

    assign wreq_valid   = axi_wvalid && axi_wready;
    assign wreq_data    = axi_wdata;
    assign wreq_strb    = axi_wstrb;
    assign wreq_last    = axi_wlast;
    assign axi_wready   = !aw_empty;

    assign axi_bready = 1'b1;
    assign axi_rready = 1'b1;

`ifdef SIM_LOG

    always @(posedge clk) begin
        if (!rst) begin
            if (if_cnt != if_cnt_next) begin
                $display("[%0d ns] %m: if_cnt %0d -> %0d", $time, if_cnt, if_cnt_next);
            end
            if (aw_cnt != aw_cnt_next) begin
                $display("[%0d ns] %m: aw_cnt %0d -> %0d", $time, aw_cnt, aw_cnt_next);
            end
        end
    end

`endif

endmodule

`default_nettype wire
