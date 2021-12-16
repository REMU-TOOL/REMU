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

    // TODO: handle aresetn in down state

    (* keep, emu_internal_sig = "CLOCK"         *)  wire model_clk;
    (* keep, emu_internal_sig = "RESET"         *)  wire model_rst;
    (* keep, emu_internal_sig = "PAUSE"         *)  wire pause;
    (* keep, emu_internal_sig = "UP_REQ"        *)  wire up_req;
    (* keep, emu_internal_sig = "DOWN_REQ"      *)  wire down_req;
    (* keep, emu_internal_sig = "UP_STAT"       *)  wire up_stat;
    (* keep, emu_internal_sig = "DOWN_STAT"     *)  wire down_stat;
    (* keep, emu_internal_sig = "STALL"         *)  wire stall;

    (* keep, emu_internal_sig = "DRAM_AWVALID"  *)
    wire                        m_axi_awvalid;
    (* keep, emu_internal_sig = "DRAM_AWREADY"  *)
    wire                        m_axi_awready;
    (* keep, emu_internal_sig = "DRAM_AWADDR"   *)
    wire    [ADDR_WIDTH-1:0]    m_axi_awaddr;
    (* keep, emu_internal_sig = "DRAM_AWID"     *)
    wire    [ID_WIDTH-1:0]      m_axi_awid;
    (* keep, emu_internal_sig = "DRAM_AWLEN"    *)
    wire    [7:0]               m_axi_awlen;
    (* keep, emu_internal_sig = "DRAM_AWSIZE"   *)
    wire    [2:0]               m_axi_awsize;
    (* keep, emu_internal_sig = "DRAM_AWBURST"  *)
    wire    [1:0]               m_axi_awburst;
    wire    [0:0]               m_axi_awlock;
    wire    [3:0]               m_axi_awcache;
    wire    [2:0]               m_axi_awprot;
    wire    [3:0]               m_axi_awqos;
    wire    [3:0]               m_axi_awregion;

    (* keep, emu_internal_sig = "DRAM_WVALID"   *)
    wire                        m_axi_wvalid;
    (* keep, emu_internal_sig = "DRAM_WREADY"   *)
    wire                        m_axi_wready;
    (* keep, emu_internal_sig = "DRAM_WDATA"    *)
    wire    [DATA_WIDTH-1:0]    m_axi_wdata;
    (* keep, emu_internal_sig = "DRAM_WSTRB"    *)
    wire    [DATA_WIDTH/8-1:0]  m_axi_wstrb;
    (* keep, emu_internal_sig = "DRAM_WLAST"    *)
    wire                        m_axi_wlast;

    (* keep, emu_internal_sig = "DRAM_BVALID"   *)
    wire                        m_axi_bvalid;
    (* keep, emu_internal_sig = "DRAM_BREADY"   *)
    wire                        m_axi_bready;
    wire    [1:0]               m_axi_bresp = 2'b00;
    (* keep, emu_internal_sig = "DRAM_BID"      *)
    wire    [ID_WIDTH-1:0]      m_axi_bid;

    (* keep, emu_internal_sig = "DRAM_ARVALID"  *)
    wire                        m_axi_arvalid;
    (* keep, emu_internal_sig = "DRAM_ARREADY"  *)
    wire                        m_axi_arready;
    (* keep, emu_internal_sig = "DRAM_ARADDR"   *)
    wire    [ADDR_WIDTH-1:0]    m_axi_araddr;
    (* keep, emu_internal_sig = "DRAM_ARID"     *)
    wire    [ID_WIDTH-1:0]      m_axi_arid;
    (* keep, emu_internal_sig = "DRAM_ARLEN"    *)
    wire    [7:0]               m_axi_arlen;
    (* keep, emu_internal_sig = "DRAM_ARSIZE"   *)
    wire    [2:0]               m_axi_arsize;
    (* keep, emu_internal_sig = "DRAM_ARBURST"  *)
    wire    [1:0]               m_axi_arburst;
    wire    [0:0]               m_axi_arlock;
    wire    [3:0]               m_axi_arcache;
    wire    [2:0]               m_axi_arprot;
    wire    [3:0]               m_axi_arqos;
    wire    [3:0]               m_axi_arregion;

    (* keep, emu_internal_sig = "DRAM_RVALID"   *)
    wire                        m_axi_rvalid;
    (* keep, emu_internal_sig = "DRAM_RREADY"   *)
    wire                        m_axi_rready;
    (* keep, emu_internal_sig = "DRAM_RDATA"    *)
    wire    [DATA_WIDTH-1:0]    m_axi_rdata;
    wire    [1:0]               m_axi_rresp = 2'b00;
    (* keep, emu_internal_sig = "DRAM_RID"      *)
    wire    [ID_WIDTH-1:0]      m_axi_rid;
    (* keep, emu_internal_sig = "DRAM_RLAST"    *)
    wire                        m_axi_rlast;

    rammodel_simple #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    )
    u_rammodel (
        .clk            (model_clk),
        .resetn         (!model_rst),
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
