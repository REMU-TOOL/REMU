`timescale 1ns / 1ps

`include "axi.vh"

module rammodel #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input                       aclk,
    input                       aresetn,

    input                       s_axi_awvalid,
    output                      s_axi_awready,
    input   [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input   [ID_WIDTH-1:0]      s_axi_awid,
    input   [7:0]               s_axi_awlen,
    input   [2:0]               s_axi_awsize,
    input   [1:0]               s_axi_awburst,
    input   [0:0]               s_axi_awlock,
    input   [3:0]               s_axi_awcache,
    input   [2:0]               s_axi_awprot,
    input   [3:0]               s_axi_awqos,
    input   [3:0]               s_axi_awregion,

    input                       s_axi_wvalid,
    output                      s_axi_wready,
    input   [DATA_WIDTH-1:0]    s_axi_wdata,
    input   [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input                       s_axi_wlast,

    output                      s_axi_bvalid,
    input                       s_axi_bready,
    output  [1:0]               s_axi_bresp,
    output  [ID_WIDTH-1:0]      s_axi_bid,

    input                       s_axi_arvalid,
    output                      s_axi_arready,
    input   [ADDR_WIDTH-1:0]    s_axi_araddr,
    input   [ID_WIDTH-1:0]      s_axi_arid,
    input   [7:0]               s_axi_arlen,
    input   [2:0]               s_axi_arsize,
    input   [1:0]               s_axi_arburst,
    input   [0:0]               s_axi_arlock,
    input   [3:0]               s_axi_arcache,
    input   [2:0]               s_axi_arprot,
    input   [3:0]               s_axi_arqos,
    input   [3:0]               s_axi_arregion,

    output                      s_axi_rvalid,
    input                       s_axi_rready,
    output  [DATA_WIDTH-1:0]    s_axi_rdata,
    output  [1:0]               s_axi_rresp,
    output  [ID_WIDTH-1:0]      s_axi_rid,
    output                      s_axi_rlast

);

    (* keep, emu_internal_sig = "CLOCK"         *)  wire model_clk;
    (* keep, emu_internal_sig = "RESET"         *)  wire model_rst;
    (* keep, emu_internal_sig = "PAUSE"         *)  wire pause;
    (* keep, emu_internal_sig = "UP_REQ"        *)  wire up_req;
    (* keep, emu_internal_sig = "DOWN_REQ"      *)  wire down_req;
    (* keep, emu_internal_sig = "UP_STAT"       *)  wire up_stat;
    (* keep, emu_internal_sig = "DOWN_STAT"     *)  wire down_stat;
    (* keep, emu_internal_sig = "STALL"         *)  wire stall;

    (* keep, emu_internal_sig = "dram_awvalid"  *)
    wire                        m_axi_awvalid;
    (* keep, emu_internal_sig = "dram_awready"  *)
    wire                        m_axi_awready;
    (* keep, emu_internal_sig = "dram_awaddr"   *)
    wire    [ADDR_WIDTH-1:0]    m_axi_awaddr;
    (* keep, emu_internal_sig = "dram_awid"     *)
    wire    [ID_WIDTH-1:0]      m_axi_awid;
    (* keep, emu_internal_sig = "dram_awlen"    *)
    wire    [7:0]               m_axi_awlen;
    (* keep, emu_internal_sig = "dram_awsize"   *)
    wire    [2:0]               m_axi_awsize;
    (* keep, emu_internal_sig = "dram_awburst"  *)
    wire    [1:0]               m_axi_awburst;
    (* keep, emu_internal_sig = "dram_awlock"  *)
    wire    [0:0]               m_axi_awlock;
    (* keep, emu_internal_sig = "dram_awcache"  *)
    wire    [3:0]               m_axi_awcache;
    (* keep, emu_internal_sig = "dram_awprot"  *)
    wire    [2:0]               m_axi_awprot;
    (* keep, emu_internal_sig = "dram_awqos"  *)
    wire    [3:0]               m_axi_awqos;
    (* keep, emu_internal_sig = "dram_awregion"  *)
    wire    [3:0]               m_axi_awregion;

    (* keep, emu_internal_sig = "dram_wvalid"   *)
    wire                        m_axi_wvalid;
    (* keep, emu_internal_sig = "dram_wready"   *)
    wire                        m_axi_wready;
    (* keep, emu_internal_sig = "dram_wdata"    *)
    wire    [DATA_WIDTH-1:0]    m_axi_wdata;
    (* keep, emu_internal_sig = "dram_wstrb"    *)
    wire    [DATA_WIDTH/8-1:0]  m_axi_wstrb;
    (* keep, emu_internal_sig = "dram_wlast"    *)
    wire                        m_axi_wlast;

    (* keep, emu_internal_sig = "dram_bvalid"   *)
    wire                        m_axi_bvalid;
    (* keep, emu_internal_sig = "dram_bready"   *)
    wire                        m_axi_bready;
    (* keep, emu_internal_sig = "dram_bresp"  *)
    wire    [1:0]               m_axi_bresp;
    (* keep, emu_internal_sig = "dram_bid"      *)
    wire    [ID_WIDTH-1:0]      m_axi_bid;

    (* keep, emu_internal_sig = "dram_arvalid"  *)
    wire                        m_axi_arvalid;
    (* keep, emu_internal_sig = "dram_arready"  *)
    wire                        m_axi_arready;
    (* keep, emu_internal_sig = "dram_araddr"   *)
    wire    [ADDR_WIDTH-1:0]    m_axi_araddr;
    (* keep, emu_internal_sig = "dram_arid"     *)
    wire    [ID_WIDTH-1:0]      m_axi_arid;
    (* keep, emu_internal_sig = "dram_arlen"    *)
    wire    [7:0]               m_axi_arlen;
    (* keep, emu_internal_sig = "dram_arsize"   *)
    wire    [2:0]               m_axi_arsize;
    (* keep, emu_internal_sig = "dram_arburst"  *)
    wire    [1:0]               m_axi_arburst;
    (* keep, emu_internal_sig = "dram_arlock"  *)
    wire    [0:0]               m_axi_arlock;
    (* keep, emu_internal_sig = "dram_arcache"  *)
    wire    [3:0]               m_axi_arcache;
    (* keep, emu_internal_sig = "dram_arprot"  *)
    wire    [2:0]               m_axi_arprot;
    (* keep, emu_internal_sig = "dram_arqos"  *)
    wire    [3:0]               m_axi_arqos;
    (* keep, emu_internal_sig = "dram_arregion"  *)
    wire    [3:0]               m_axi_arregion;

    (* keep, emu_internal_sig = "dram_rvalid"   *)
    wire                        m_axi_rvalid;
    (* keep, emu_internal_sig = "dram_rready"   *)
    wire                        m_axi_rready;
    (* keep, emu_internal_sig = "dram_rdata"    *)
    wire    [DATA_WIDTH-1:0]    m_axi_rdata;
    (* keep, emu_internal_sig = "dram_rresp"  *)
    wire    [1:0]               m_axi_rresp;
    (* keep, emu_internal_sig = "dram_rid"      *)
    wire    [ID_WIDTH-1:0]      m_axi_rid;
    (* keep, emu_internal_sig = "dram_rlast"    *)
    wire                        m_axi_rlast;

    rammodel_simple #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .R_DELAY    (R_DELAY),
        .W_DELAY    (W_DELAY)
    )
    u_rammodel (
        .clk            (model_clk),
        .resetn         (!model_rst),
        .dut_resetn     (aresetn),
        `AXI4_CONNECT   (s_dut, s_axi),
        `AXI4_CONNECT   (m_dram, m_axi),
        .pause          (pause),
        .up_req         (up_req),
        .down_req       (down_req),
        .up             (up_stat),
        .down           (down_stat),
        .dut_stall      (stall)
    );

endmodule
