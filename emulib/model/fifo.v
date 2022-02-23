`resetall
`timescale 1ns / 1ps
`default_nettype none

module emulib_fifo #(
    parameter WIDTH         = 32,
    parameter DEPTH         = 8,
    parameter USE_SRSW      = 0
)(
    input  wire                 clk,
    input  wire                 rst,

    input  wire                 ivalid,
    output wire                 iready,
    input  wire [WIDTH-1:0]     idata,

    output wire                 ovalid,
    input  wire                 oready,
    output wire [WIDTH-1:0]     odata,

    output wire                 full,
    output wire                 empty
);

    localparam DEPTH_LOG2 = $clog2(DEPTH);
    localparam [DEPTH_LOG2-1:0]
        PTR_MAX = DEPTH - 1,
        PTR_ZRO = 0,
        PTR_INC = 1;

    reg [WIDTH-1:0] data [(1<<DEPTH_LOG2)-1:0];
    reg [DEPTH_LOG2-1:0] rp, wp;
    reg full_n, empty_n;

    wire do_w, do_r;
    wire [DEPTH_LOG2-1:0] rp_inc, wp_inc;

    if (PTR_MAX + PTR_INC == PTR_ZRO) begin
        assign rp_inc = rp + PTR_INC;
        assign wp_inc = wp + PTR_INC;
    end
    else begin
        assign rp_inc = rp == PTR_MAX ? PTR_ZRO : rp + PTR_INC;
        assign wp_inc = wp == PTR_MAX ? PTR_ZRO : wp + PTR_INC;
    end

    always @(posedge clk)
        if (rst)
            wp <= PTR_ZRO;
        else if (do_w)
            wp <= wp_inc;

    always @(posedge clk)
        if (rst)
            rp <= PTR_ZRO;
        else if (do_r)
            rp <= rp_inc;

    always @(posedge clk) begin
        if (rst) begin
            full_n  <= 1'b1;
            empty_n <= 1'b0;
        end
        else if (do_w ^ do_r) begin
            full_n  <= !do_w || (wp_inc != rp);
            empty_n <= !do_r || (rp_inc != wp);
        end
    end

    always @(posedge clk) if (do_w) data[wp] <= idata;

    if (USE_SRSW) begin

        reg ovalid_r;
        reg [WIDTH-1:0] rdata;

        wire rvalid = empty_n;
        wire rready = !ovalid || oready;

        assign do_w     = ivalid && iready;
        assign do_r     = rvalid && rready;

        always @(posedge clk)
            if (rst)
                ovalid_r <= 1'b0;
            else if (rvalid)
                ovalid_r <= 1'b1;
            else if (oready)
                ovalid_r <= 1'b0;

        always @(posedge clk)
            if (do_r)
                rdata <= data[rp];

        assign iready   = full_n;
        assign ovalid   = ovalid_r;
        assign odata    = rdata;

    end
    else begin

        assign do_w     = ivalid && iready;
        assign do_r     = ovalid && oready;

        assign iready   = full_n;
        assign ovalid   = empty_n;
        assign odata    = data[rp];

    end

    assign full     = !iready;
    assign empty    = !ovalid;

endmodule

`resetall
