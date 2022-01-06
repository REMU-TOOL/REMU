`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"

module rammodel #(
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

    (* keep, emu_intf_port = "clk"              *) wire model_clk;
    (* keep, emu_intf_port = "rst"              *) wire model_rst;
    (* keep, emu_intf_port = "stall"            *) wire stall;
    (* keep, emu_intf_port = "stall_gen"        *) wire stall_gen;
    (* keep, emu_intf_port = "up_req"           *) wire up_req;
    (* keep, emu_intf_port = "down_req"         *) wire down_req;
    (* keep, emu_intf_port = "up_stat"          *) wire up_stat;
    (* keep, emu_intf_port = "down_stat"        *) wire down_stat;

    (* keep, emu_intf_port = "dram_awvalid"     *)
    wire                        m_axi_awvalid;
    (* keep, emu_intf_port = "dram_awready"     *)
    wire                        m_axi_awready;
    (* keep, emu_intf_port = "dram_awaddr"      *)
    wire    [ADDR_WIDTH-1:0]    m_axi_awaddr;
    (* keep, emu_intf_port = "dram_awid"        *)
    wire    [ID_WIDTH-1:0]      m_axi_awid;
    (* keep, emu_intf_port = "dram_awlen"       *)
    wire    [7:0]               m_axi_awlen;
    (* keep, emu_intf_port = "dram_awsize"      *)
    wire    [2:0]               m_axi_awsize;
    (* keep, emu_intf_port = "dram_awburst"     *)
    wire    [1:0]               m_axi_awburst;
    (* keep, emu_intf_port = "dram_awlock"      *)
    wire    [0:0]               m_axi_awlock;
    (* keep, emu_intf_port = "dram_awcache"     *)
    wire    [3:0]               m_axi_awcache;
    (* keep, emu_intf_port = "dram_awprot"      *)
    wire    [2:0]               m_axi_awprot;
    (* keep, emu_intf_port = "dram_awqos"       *)
    wire    [3:0]               m_axi_awqos;
    (* keep, emu_intf_port = "dram_awregion"    *)
    wire    [3:0]               m_axi_awregion;

    (* keep, emu_intf_port = "dram_wvalid"      *)
    wire                        m_axi_wvalid;
    (* keep, emu_intf_port = "dram_wready"      *)
    wire                        m_axi_wready;
    (* keep, emu_intf_port = "dram_wdata"       *)
    wire    [DATA_WIDTH-1:0]    m_axi_wdata;
    (* keep, emu_intf_port = "dram_wstrb"       *)
    wire    [DATA_WIDTH/8-1:0]  m_axi_wstrb;
    (* keep, emu_intf_port = "dram_wlast"       *)
    wire                        m_axi_wlast;

    (* keep, emu_intf_port = "dram_bvalid"      *)
    wire                        m_axi_bvalid;
    (* keep, emu_intf_port = "dram_bready"      *)
    wire                        m_axi_bready;
    (* keep, emu_intf_port = "dram_bresp"       *)
    wire    [1:0]               m_axi_bresp;
    (* keep, emu_intf_port = "dram_bid"         *)
    wire    [ID_WIDTH-1:0]      m_axi_bid;

    (* keep, emu_intf_port = "dram_arvalid"     *)
    wire                        m_axi_arvalid;
    (* keep, emu_intf_port = "dram_arready"     *)
    wire                        m_axi_arready;
    (* keep, emu_intf_port = "dram_araddr"      *)
    wire    [ADDR_WIDTH-1:0]    m_axi_araddr;
    (* keep, emu_intf_port = "dram_arid"        *)
    wire    [ID_WIDTH-1:0]      m_axi_arid;
    (* keep, emu_intf_port = "dram_arlen"       *)
    wire    [7:0]               m_axi_arlen;
    (* keep, emu_intf_port = "dram_arsize"      *)
    wire    [2:0]               m_axi_arsize;
    (* keep, emu_intf_port = "dram_arburst"     *)
    wire    [1:0]               m_axi_arburst;
    (* keep, emu_intf_port = "dram_arlock"      *)
    wire    [0:0]               m_axi_arlock;
    (* keep, emu_intf_port = "dram_arcache"     *)
    wire    [3:0]               m_axi_arcache;
    (* keep, emu_intf_port = "dram_arprot"      *)
    wire    [2:0]               m_axi_arprot;
    (* keep, emu_intf_port = "dram_arqos"       *)
    wire    [3:0]               m_axi_arqos;
    (* keep, emu_intf_port = "dram_arregion"    *)
    wire    [3:0]               m_axi_arregion;

    (* keep, emu_intf_port = "dram_rvalid"      *)
    wire                        m_axi_rvalid;
    (* keep, emu_intf_port = "dram_rready"      *)
    wire                        m_axi_rready;
    (* keep, emu_intf_port = "dram_rdata"       *)
    wire    [DATA_WIDTH-1:0]    m_axi_rdata;
    (* keep, emu_intf_port = "dram_rresp"       *)
    wire    [1:0]               m_axi_rresp;
    (* keep, emu_intf_port = "dram_rid"         *)
    wire    [ID_WIDTH-1:0]      m_axi_rid;
    (* keep, emu_intf_port = "dram_rlast"       *)
    wire                        m_axi_rlast;

    wire mrg_stall, mrg_down, mrg_rst;

    (* emu_no_scanchain *)
    rst_down_gen u_rst_down_gen (
        .clk            (model_clk),
        .rst            (model_rst),
        .dut_rst        (!aresetn),
        .stall          (stall),
        .stall_gen      (mrg_stall),
        .down_req       (mrg_down),
        .down_stat      (down_stat),
        .rst_gen        (mrg_rst)
    );

    wire rammodel_stall_gen;

    rammodel_simple #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .R_DELAY    (R_DELAY),
        .W_DELAY    (W_DELAY)
    )
    u_rammodel (
        .clk            (model_clk),
        .resetn         (!(model_rst || mrg_rst)),
        `AXI4_CONNECT   (s_dut, s_axi),
        `AXI4_CONNECT   (m_dram, m_axi),
        .stall          (stall),
        .up_req         (up_req),
        .down_req       (down_req || mrg_down),
        .up             (up_stat),
        .down           (down_stat),
        .stall_gen      (rammodel_stall_gen)
    );

    assign stall_gen = rammodel_stall_gen || mrg_stall;

endmodule

`resetall
