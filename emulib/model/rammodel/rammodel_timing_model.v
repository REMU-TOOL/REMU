`timescale 1ns / 1ps

module emulib_rammodel_timing_model #(
    parameter   ADDR_WIDTH      = 32,
    parameter   ID_WIDTH        = 4,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8,
    parameter   TIMING_TYPE     = "fixed"
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

`define CONNECT_INST_PORTS \
    .clk        (clk    ), \
    .rst        (rst    ), \
    .arvalid    (arvalid), \
    .arready    (arready), \
    .arid       (arid   ), \
    .araddr     (araddr ), \
    .arlen      (arlen  ), \
    .arsize     (arsize ), \
    .arburst    (arburst), \
    .awvalid    (awvalid), \
    .awready    (awready), \
    .awid       (awid   ), \
    .awaddr     (awaddr ), \
    .awlen      (awlen  ), \
    .awsize     (awsize ), \
    .awburst    (awburst), \
    .wvalid     (wvalid ), \
    .wready     (wready ), \
    .wlast      (wlast  ), \
    .bvalid     (bvalid ), \
    .bready     (bready ), \
    .bid        (bid    ), \
    .rvalid     (rvalid ), \
    .rready     (rready ), \
    .rid        (rid    )

    if (TIMING_TYPE == "fixed") begin : fixed
        emulib_rammodel_timing_model_fixed #(
            .ADDR_WIDTH     (ADDR_WIDTH),
            .ID_WIDTH       (ID_WIDTH),
            .MAX_R_INFLIGHT (MAX_R_INFLIGHT),
            .MAX_W_INFLIGHT (MAX_W_INFLIGHT)
        ) inst (
            `CONNECT_INST_PORTS
        );
    end
    else if (TIMING_TYPE == "fased") begin : fased
        emulib_rammodel_FIFOMAS #(
            .ADDR_WIDTH     (ADDR_WIDTH),
            .ID_WIDTH       (ID_WIDTH),
            .MAX_R_INFLIGHT (MAX_R_INFLIGHT),
            .MAX_W_INFLIGHT (MAX_W_INFLIGHT)
        ) inst (
            `CONNECT_INST_PORTS
        );
    end
    else begin
        initial begin
            $display("%m: unrecognized timing model type %s", TIMING_TYPE);
            $finish;
        end
    end

endmodule
