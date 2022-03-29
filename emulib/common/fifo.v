`timescale 1ns / 1ps
`default_nettype none

module emulib_fifo #(
    parameter WIDTH     = 32,
    parameter DEPTH     = 8,
    parameter USE_BURST = 0,

    parameter CNTW      = $clog2(DEPTH)
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 ivalid,
    output reg                  iready,
    input  wire [WIDTH-1:0]     idata,
    input  wire                 ilast,

    output reg                  ovalid,
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

    // Counter operations

    localparam [CNTW-1:0]
        PTR_MAX = DEPTH - 1,
        PTR_ZRO = 0,
        PTR_INC = 1;

    reg [RAMW-1:0] data [DEPTH-1:0];
    reg [CNTW-1:0] rp, wp;

    reg rfire;

    wire ifire = ivalid && iready;
    wire ofire = ovalid && oready;

    wire [CNTW-1:0] rp_inc = rp == PTR_MAX ? PTR_ZRO : rp + PTR_INC;
    wire [CNTW-1:0] wp_inc = wp == PTR_MAX ? PTR_ZRO : wp + PTR_INC;

    wire [CNTW-1:0] rp_next = ofire ? rp_inc : rp;
    wire [CNTW-1:0] wp_next = ifire ? wp_inc : wp;

    always @(posedge clk)
        if (rst)
            wp <= PTR_ZRO;
        else
            wp <= wp_next;

    always @(posedge clk)
        if (rst)
            rp <= PTR_ZRO;
        else
            rp <= rp_next;

    always @(posedge clk)
        if (rst)
            iready <= 1'b1;
        else if (ofire)
            iready <= 1'b1;
        else if (ifire && wp_inc == rp)
            iready <= 1'b0;

    always @(posedge clk)
        if (rst)
            rfire <= 1'b0;
        else
            rfire <= ifire;

    always @(posedge clk)
        if (rst)
            ovalid <= 1'b0;
        else if (rfire)
            ovalid <= 1'b1;
        else if (ofire && rp_inc == wp)
            ovalid <= 1'b0;

    // Write RAM

    wire [RAMW-1:0] wdata;

    if (USE_BURST)
        assign wdata = {idata, ilast};
    else
        assign wdata = idata;

    always @(posedge clk) if (ifire) data[wp] <= wdata;

    // Read RAM

    reg [RAMW-1:0] rdata;

    always @(posedge clk)
        rdata <= data[rp_next];

    // Output data

    if (USE_BURST)
        assign {odata, olast} = rdata;
    else
        assign {odata, olast} = {rdata, 1'b1};

    // Flags

    assign full     = !iready;
    assign empty    = !ovalid && !rfire;

    // Counters

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

`ifdef SIM_LOG_FIFO

    always @(posedge clk) begin
        if (!rst) begin
            if (USE_BURST) begin
                case ({ivalid && iready, ovalid && oready})
                    2'b01: begin
                        $display("[%0d ns] %m: %0s: %h, %0d/%0d, bursts=%0d", $time,
                            olast ? "OUT (LAST)" : "OUT", odata,
                            item_cnt - 1, DEPTH, burst_cnt - olast);
                    end
                    2'b10: begin
                        $display("[%0d ns] %m: %0s: %h, %0d/%0d, bursts=%0d", $time,
                            ilast ? "IN (LAST)" : "IN", idata,
                            item_cnt + 1, DEPTH, burst_cnt + ilast);
                    end
                    2'b11: begin
                        $display("[%0d ns] %m: %0s: %h, %0s: %h, %0d/%0d, bursts=%0d", $time,
                            ilast ? "IN (LAST)" : "IN", idata,
                            olast ? "OUT (LAST)" : "OUT", odata,
                            item_cnt, DEPTH, burst_cnt + ilast - olast);
                    end
                endcase
            end
            else begin
                case ({ivalid && iready, ovalid && oready})
                    2'b01: begin
                        $display("[%0d ns] %m: OUT: %h, %0d/%0d", $time, odata, item_cnt - 1, DEPTH);
                    end
                    2'b10: begin
                        $display("[%0d ns] %m: IN: %h, %0d/%0d", $time, idata, item_cnt + 1, DEPTH);
                    end
                    2'b11: begin
                        $display("[%0d ns] %m: IN: %h, OUT: %h, %0d/%0d", $time, idata, odata, item_cnt, DEPTH);
                    end
                endcase
            end
        end
    end

`endif

`ifdef FORMAL

    reg f_past_valid;
    initial f_past_valid = 1'b0;

    always @(posedge clk)
        f_past_valid <= 1'b1;

    always @*
        if (!f_past_valid)
            assume(rst);

    integer f_depth;

    always @(posedge clk) begin
        if (rst)
            f_depth <= 0;
        else
            f_depth <= f_depth + ifire - ofire;
    end

    always @(posedge clk) begin
        if (!rst) begin
            assert(f_depth <= DEPTH);
            assert(f_depth >= 0);
            assert((f_depth == 0)       == empty);
            assert((f_depth == DEPTH)   == full);
            assert(!full || !empty);
        end
    end

`endif

endmodule

`default_nettype wire
