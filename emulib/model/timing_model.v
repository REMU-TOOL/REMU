`resetall
`timescale 1ns / 1ps
`default_nettype none

module rammodel_simple_timing_model #(
    parameter   ADDR_WIDTH      = 32,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(
    input  wire                     clk,
    input  wire                     resetn,

    input  wire                     arvalid,
    output wire                     arready,
    input  wire [ADDR_WIDTH-1:0]    araddr,
    input  wire [7:0]               arlen,
    input  wire [2:0]               arsize,
    input  wire [1:0]               arburst,

    output wire                     rvalid,
    input  wire                     rready,

    input  wire                     awvalid,
    output wire                     awready,
    input  wire [ADDR_WIDTH-1:0]    awaddr,
    input  wire [7:0]               awlen,
    input  wire [2:0]               awsize,
    input  wire [1:0]               awburst,

    input  wire                     wvalid,
    output wire                     wready,
    input  wire                     wlast,

    output wire                     bvalid,
    input  wire                     bready,

    input  wire                     stall

);

    reg [7:0] rlen;
    reg ar, aw, w;

    reg [15:0] rcnt, wcnt;

    always @(posedge clk) begin
        if (!resetn)
            rlen <= 7'd0;
        else if (!stall) begin
            if (arvalid && arready)
                rlen <= arlen;
            else if (rvalid && rready)
                rlen <= rlen - 7'd1;
        end
    end

    always @(posedge clk) begin
        if (!resetn)
            ar <= 1'b0;
        else if (!stall) begin
            if (arvalid && arready)
                ar <= 1'b1;
            else if (rvalid && rready && rlen == 7'd0)
                ar <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!resetn)
            rcnt <= 16'd0;
        else if (!stall) begin
            if (arvalid && arready)
                rcnt <= R_DELAY;
            else if (rcnt != 16'd0)
                rcnt <= rcnt - 16'd1;
        end
    end

    always @(posedge clk) begin
        if (!resetn)
            aw <= 1'b0;
        else if (!stall) begin
            if (awvalid && awready)
                aw <= 1'b1;
            else if (bvalid && bready)
                aw <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!resetn)
            w <= 1'b0;
        else if (!stall) begin
            if (wvalid && wready && wlast)
                w <= 1'b1;
            else if (bvalid && bready)
                w <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (!resetn)
            wcnt <= 16'd0;
        else if (!stall) begin
            if (wvalid && wready && wlast)
                wcnt <= W_DELAY;
            else if (wcnt != 16'd0)
                wcnt <= wcnt - 16'd1;
        end
    end

    assign arready  = 1'b1;
    assign rvalid   = ar && rcnt == 16'd0;
    assign awready  = 1'b1;
    assign wready   = 1'b1;
    assign bvalid   = aw && w && wcnt == 16'd0;

endmodule

`resetall
