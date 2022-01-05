`resetall
`timescale 1ns / 1ps
`default_nettype none

(* keep, emulib_component = "rammodel" *)
module RAMModel #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input  wire                     aclk,
    input  wire                     aresetn,

    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [ID_WIDTH-1:0]      s_axi_awid,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire [0:0]               s_axi_awlock,
    input  wire [3:0]               s_axi_awcache,
    input  wire [2:0]               s_axi_awprot,
    input  wire [3:0]               s_axi_awqos,
    input  wire [3:0]               s_axi_awregion,

    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  wire                     s_axi_wlast,

    output wire                     s_axi_bvalid,
    input  wire                     s_axi_bready,
    output wire [1:0]               s_axi_bresp,
    output wire [ID_WIDTH-1:0]      s_axi_bid,

    input  wire                     s_axi_arvalid,
    output wire                     s_axi_arready,
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [ID_WIDTH-1:0]      s_axi_arid,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire [0:0]               s_axi_arlock,
    input  wire [3:0]               s_axi_arcache,
    input  wire [2:0]               s_axi_arprot,
    input  wire [3:0]               s_axi_arqos,
    input  wire [3:0]               s_axi_arregion,

    output wire                     s_axi_rvalid,
    input  wire                     s_axi_rready,
    output wire [DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [1:0]               s_axi_rresp,
    output wire [ID_WIDTH-1:0]      s_axi_rid,
    output wire                     s_axi_rlast

);

endmodule

`resetall
