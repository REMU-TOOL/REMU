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

    input  wire                 target_clk,
    input  wire                 target_rst,

    `AXI4_AW_SLAVE_IF           (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_W_SLAVE_IF            (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_AR_SLAVE_IF           (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    `AXI4_B_SLAVE_IF            (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_R_SLAVE_IF            (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    `AXI4_CUSTOM_A_MASTER_IF    (backend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_CUSTOM_W_MASTER_IF    (backend, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)

);

    // AW/AR arbitration

    `AXI4_CUSTOM_A_WIRE(arb, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    emulib_ready_valid_arb #(
        .NUM_S      (2),
        .DATA_WIDTH (`AXI4_CUSTOM_A_PAYLOAD_LEN(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH))
    ) aw_ar_arb (
        .s_valid    ({axi_awvalid, axi_arvalid}),
        .s_ready    ({axi_awready, axi_arready}),
        .s_data     ({`AXI4_CUSTOM_A_PAYLOAD_FROM_AW(axi), `AXI4_CUSTOM_A_PAYLOAD_FROM_AR(axi)}),
        .m_valid    (arb_avalid),
        .m_ready    (arb_aready),
        .m_data     (`AXI4_CUSTOM_A_PAYLOAD(arb)),
        .m_sel      ()
    );

    // In-flight counter

    localparam IF_CNT_LEN = $clog2(MAX_INFLIGHT) + 1;

    reg [IF_CNT_LEN-1:0] if_cnt, if_cnt_next;

    always @(posedge target_clk)
        if (target_rst)
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

    always @(posedge target_clk)
        if (target_rst)
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

    assign backend_avalid   = arb_avalid && !if_full;
    assign arb_aready       = backend_aready && !if_full;

    assign `AXI4_CUSTOM_A_PAYLOAD(backend) = `AXI4_CUSTOM_A_PAYLOAD(arb);

    assign backend_wvalid   = axi_wvalid && !aw_empty;
    assign axi_wready       = backend_wready && !aw_empty;

    assign `AXI4_CUSTOM_W_PAYLOAD(backend) = `AXI4_CUSTOM_W_PAYLOAD(axi);

    assign axi_bready = 1'b1;
    assign axi_rready = 1'b1;

`ifdef SIM_LOG

    always @(posedge target_clk) begin
        if (!target_rst) begin
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
