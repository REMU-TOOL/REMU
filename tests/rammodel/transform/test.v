`timescale 1ns / 1ps

`include "axi.vh"

module test #(
    // DO NOT CHANGE
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input                       host_clk,
    input                       host_rst,

    output                      target_clk,
    input                       target_rst,

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
    output                      s_axi_rlast,

    output                      m_axi_awvalid,
    input                       m_axi_awready,
    output  [ADDR_WIDTH-1:0]    m_axi_awaddr,
    output  [ID_WIDTH-1:0]      m_axi_awid,
    output  [7:0]               m_axi_awlen,
    output  [2:0]               m_axi_awsize,
    output  [1:0]               m_axi_awburst,
    output  [0:0]               m_axi_awlock,
    output  [3:0]               m_axi_awcache,
    output  [2:0]               m_axi_awprot,
    output  [3:0]               m_axi_awqos,
    output  [3:0]               m_axi_awregion,

    output                      m_axi_wvalid,
    input                       m_axi_wready,
    output  [DATA_WIDTH-1:0]    m_axi_wdata,
    output  [DATA_WIDTH/8-1:0]  m_axi_wstrb,
    output                      m_axi_wlast,

    input                       m_axi_bvalid,
    output                      m_axi_bready,
    input   [1:0]               m_axi_bresp,
    input   [ID_WIDTH-1:0]      m_axi_bid,

    output                      m_axi_arvalid,
    input                       m_axi_arready,
    output  [ADDR_WIDTH-1:0]    m_axi_araddr,
    output  [ID_WIDTH-1:0]      m_axi_arid,
    output  [7:0]               m_axi_arlen,
    output  [2:0]               m_axi_arsize,
    output  [1:0]               m_axi_arburst,
    output  [0:0]               m_axi_arlock,
    output  [3:0]               m_axi_arcache,
    output  [2:0]               m_axi_arprot,
    output  [3:0]               m_axi_arqos,
    output  [3:0]               m_axi_arregion,

    input                       m_axi_rvalid,
    output                      m_axi_rready,
    input   [DATA_WIDTH-1:0]    m_axi_rdata,
    input   [1:0]               m_axi_rresp,
    input   [ID_WIDTH-1:0]      m_axi_rid,
    input                       m_axi_rlast,

    input                       pause,

    input                       ff_scan,
    input                       ff_dir,
    input   [63:0]              ff_sdi,
    output  [63:0]              ff_sdo,
    input                       ram_scan_reset,
    input                       ram_scan,
    input                       ram_dir,
    input   [63:0]              ram_sdi,
    output  [63:0]              ram_sdo,

    input                       run_mode,
    input                       scan_mode,
    output                      idle

);

    EMU_SYSTEM emu_dut(

        .target_s_axi_awvalid  (s_axi_awvalid),
        .target_s_axi_awready  (s_axi_awready),
        .target_s_axi_awaddr   (s_axi_awaddr),
        .target_s_axi_awid     (s_axi_awid),
        .target_s_axi_awlen    (s_axi_awlen),
        .target_s_axi_awsize   (s_axi_awsize),
        .target_s_axi_awburst  (s_axi_awburst),
        .target_s_axi_awlock   (s_axi_awlock),
        .target_s_axi_awcache  (s_axi_awcache),
        .target_s_axi_awprot   (s_axi_awprot),
        .target_s_axi_awqos    (s_axi_awqos),
        .target_s_axi_awregion (s_axi_awregion),

        .target_s_axi_wvalid   (s_axi_wvalid),
        .target_s_axi_wready   (s_axi_wready),
        .target_s_axi_wdata    (s_axi_wdata),
        .target_s_axi_wstrb    (s_axi_wstrb),
        .target_s_axi_wlast    (s_axi_wlast),

        .target_s_axi_bvalid   (s_axi_bvalid),
        .target_s_axi_bready   (s_axi_bready),
        .target_s_axi_bresp    (s_axi_bresp),
        .target_s_axi_bid      (s_axi_bid),

        .target_s_axi_arvalid  (s_axi_arvalid),
        .target_s_axi_arready  (s_axi_arready),
        .target_s_axi_araddr   (s_axi_araddr),
        .target_s_axi_arid     (s_axi_arid),
        .target_s_axi_arlen    (s_axi_arlen),
        .target_s_axi_arsize   (s_axi_arsize),
        .target_s_axi_arburst  (s_axi_arburst),
        .target_s_axi_arlock   (s_axi_arlock),
        .target_s_axi_arcache  (s_axi_arcache),
        .target_s_axi_arprot   (s_axi_arprot),
        .target_s_axi_arqos    (s_axi_arqos),
        .target_s_axi_arregion (s_axi_arregion),

        .target_s_axi_rvalid   (s_axi_rvalid),
        .target_s_axi_rready   (s_axi_rready),
        .target_s_axi_rdata    (s_axi_rdata),
        .target_s_axi_rresp    (s_axi_rresp),
        .target_s_axi_rid      (s_axi_rid),
        .target_s_axi_rlast    (s_axi_rlast),

        .host_clk       (host_clk),
        .host_rst       (host_rst),
        .ff_se          (ff_scan),
        .ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .ff_do          (ff_sdo),
        .ram_sr         (ram_scan_reset),
        .ram_se         (ram_scan),
        .ram_sd         (ram_dir),
        .ram_di         (ram_sdi),
        .ram_do         (ram_sdo),
        .reset_dut_rst  (target_rst),
        .run_mode       (run_mode),
        .scan_mode      (scan_mode),
        .idle           (idle),
        `AXI4_CONNECT       (target_u_rammodel_backend_host_axi, m_axi)
    );

    assign target_clk = emu_dut.clock_dut_clk;

endmodule
