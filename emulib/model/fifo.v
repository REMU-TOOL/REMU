`resetall
`timescale 1ns / 1ps
`default_nettype none

module emulib_fifo #(
    parameter WIDTH     = 32,
    parameter DEPTH     = 8,
    parameter USE_BURST = 0,
    parameter USE_SRSW  = 0,

    parameter CNTW      = $clog2(DEPTH)
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 ivalid,
    output wire                 iready,
    input  wire [WIDTH-1:0]     idata,
    input  wire                 ilast,

    output wire                 ovalid,
    input  wire                 oready,
    output wire [WIDTH-1:0]     odata,
    output wire                 olast,

    output wire                 full,
    output wire                 empty,

    output reg  [CNTW:0]        item_cnt,
    output reg  [CNTW:0]        burst_cnt

);

    // Extend RAM width by 1 to store the last flag
    localparam RAMW = WIDTH + (USE_BURST != 0);
    // Reduce RAM depth by 1 if SRSW RAM is used
    // Because the output register provides 1 extra storage
    localparam RAMD = DEPTH - (USE_SRSW != 0);

    // Counter operations

    localparam [CNTW-1:0]
        PTR_MAX = RAMD - 1,
        PTR_ZRO = 0,
        PTR_INC = 1;

    reg [RAMW-1:0] data [RAMD-1:0];
    reg [CNTW-1:0] rp, wp;
    reg full_n, empty_n;

    wire do_w, do_r;
    wire [CNTW-1:0] rp_inc, wp_inc;

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

    always @(posedge clk) begin
        if (rst)
            item_cnt <= 0;
        else
            item_cnt <= item_cnt + (ivalid && iready) - (ovalid && oready);
    end

    if (USE_BURST)
        always @(posedge clk) begin
            if (rst)
                burst_cnt <= 0;
            else
                burst_cnt <= burst_cnt + (ivalid && iready && ilast) - (ovalid && oready && olast);
        end
    else
        always @* burst_cnt = item_cnt;

    // Write RAM

    wire [RAMW-1:0] wdata;

    if (USE_BURST)
        assign wdata = {idata, ilast};
    else
        assign wdata = idata;

    always @(posedge clk) if (do_w) data[wp] <= wdata;

    // Read RAM

    reg [RAMW-1:0] rdata;

    if (USE_SRSW) begin

        reg ovalid_r;

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

    end
    else begin

        assign do_w     = ivalid && iready;
        assign do_r     = ovalid && oready;

        assign iready   = full_n;
        assign ovalid   = empty_n;

        always @* rdata = data[rp];

    end

    // Output data

    if (USE_BURST)
        assign {odata, olast} = rdata;
    else
        assign {odata, olast} = {rdata, 1'b1};

    assign full     = !iready;
    assign empty    = !ovalid;

`ifdef SIM_LOG

    always @(posedge clk) begin
        if (!rst) begin
            if (USE_BURST) begin
                case ({ivalid && iready, ovalid && oready})
                    2'b01: begin
                        $display("[%0d ns] %m: %0s, %0d/%0d, bursts=%0d", $time,
                            olast ? "OUT (LAST)" : "OUT",
                            item_cnt - 1, DEPTH, burst_cnt - olast);
                    end
                    2'b10: begin
                        $display("[%0d ns] %m: %0s, %0d/%0d, bursts=%0d", $time,
                            ilast ? "IN (LAST)" : "IN",
                            item_cnt + 1, DEPTH, burst_cnt + ilast);
                    end
                    2'b11: begin
                        $display("[%0d ns] %m: %0s, %0s, %0d/%0d, bursts=%0d", $time,
                            ilast ? "IN (LAST)" : "IN",
                            olast ? "OUT (LAST)" : "OUT",
                            item_cnt, DEPTH, burst_cnt + ilast - olast);
                    end
                endcase
            end
            else begin
                case ({ivalid && iready, ovalid && oready})
                    2'b01: begin
                        $display("[%0d ns] %m: OUT, %0d/%0d", $time, item_cnt - 1, DEPTH);
                    end
                    2'b10: begin
                        $display("[%0d ns] %m: IN, %0d/%0d", $time, item_cnt + 1, DEPTH);
                    end
                    2'b11: begin
                        $display("[%0d ns] %m: IN, OUT, %0d/%0d", $time, item_cnt, DEPTH);
                    end
                endcase
            end
        end
    end

`endif

endmodule

`resetall
