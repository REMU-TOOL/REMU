`timescale 1ns / 1ps

module emulib_rammodel_tm_fixed #(
    parameter   ADDR_WIDTH      = 32,
    parameter   ID_WIDTH        = 4,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
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

    reg ar, aw, w;

    reg [15:0] rcnt, wcnt;

    reg [7:0] rlen;

    always @(posedge clk) begin
        if (rst)
            ar <= 1'b0;
        else if (arvalid && arready)
            ar <= 1'b1;
        else if (rvalid && rready && rlen == 8'd0)
            ar <= 1'b0;
    end

    always @(posedge clk) begin
        if (rst)
            aw <= 1'b0;
        else if (awvalid && awready)
            aw <= 1'b1;
        else if (bvalid && bready)
            aw <= 1'b0;
    end

    always @(posedge clk) begin
        if (rst)
            w <= 1'b0;
        else if (wvalid && wready && wlast)
            w <= 1'b1;
        else if (bvalid && bready)
            w <= 1'b0;
    end

    always @(posedge clk) begin
        if (rst)
            rcnt <= 16'd0;
        else if (arvalid && arready)
            rcnt <= R_DELAY;
        else if (rcnt != 16'd0)
            rcnt <= rcnt - 16'd1;
    end

    always @(posedge clk) begin
        if (rst)
            wcnt <= 16'd0;
        else if (wvalid && wready && wlast)
            wcnt <= W_DELAY;
        else if (wcnt != 16'd0)
            wcnt <= wcnt - 16'd1;
    end

    always @(posedge clk) begin
        if (rst)
            rlen <= 8'd0;
        else if (arvalid && arready)
            rlen <= arlen;
        else if (rvalid && rready)
            rlen <= rlen - 8'd1;
    end

    assign arready      = !ar;
    assign awready      = !aw;
    assign wready       = aw;

    assign bvalid       = aw && w && wcnt == 16'd0;
    assign bid          = 0; // TODO

    assign rvalid       = ar && rcnt == 16'd0;
    assign rid          = 0; // TODO

endmodule
