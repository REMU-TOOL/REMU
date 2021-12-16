`timescale 1ns / 1ps

module rammodel_simple_timing_model #(
    parameter   ADDR_WIDTH      = 32,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(
    input                       clk,
    input                       resetn,

    input                       arvalid,
    output                      arready,
    input   [ADDR_WIDTH-1:0]    araddr,
    input   [7:0]               arlen,
    input   [2:0]               arsize,
    input   [1:0]               arburst,

    output                      rvalid,
    input                       rready,

    input                       awvalid,
    output                      awready,
    input   [ADDR_WIDTH-1:0]    awaddr,
    input   [7:0]               awlen,
    input   [2:0]               awsize,
    input   [1:0]               awburst,

    input                       wvalid,
    output                      wready,
    input                       wlast,

    output                      bvalid,
    input                       bready,

    input                       stall

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
