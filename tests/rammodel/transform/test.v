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

    input                       ff_scan,
    input                       ff_dir,
    input                       ff_sdi,
    output                      ff_sdo,
    input                       ram_scan_reset,
    input                       ram_scan,
    input                       ram_dir,
    input                       ram_sdi,
    output                      ram_sdo,

    input                       run_mode,
    input                       scan_mode,
    output                      idle

);

    EMU_SYSTEM emu_dut(

        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),
        .s_axi_awaddr   (s_axi_awaddr),
        .s_axi_awid     (s_axi_awid),
        .s_axi_awlen    (s_axi_awlen),
        .s_axi_awsize   (s_axi_awsize),
        .s_axi_awburst  (s_axi_awburst),
        .s_axi_awlock   (s_axi_awlock),
        .s_axi_awcache  (s_axi_awcache),
        .s_axi_awprot   (s_axi_awprot),
        .s_axi_awqos    (s_axi_awqos),
        .s_axi_awregion (s_axi_awregion),

        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),
        .s_axi_wdata    (s_axi_wdata),
        .s_axi_wstrb    (s_axi_wstrb),
        .s_axi_wlast    (s_axi_wlast),

        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),
        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bid      (s_axi_bid),

        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (s_axi_arready),
        .s_axi_araddr   (s_axi_araddr),
        .s_axi_arid     (s_axi_arid),
        .s_axi_arlen    (s_axi_arlen),
        .s_axi_arsize   (s_axi_arsize),
        .s_axi_arburst  (s_axi_arburst),
        .s_axi_arlock   (s_axi_arlock),
        .s_axi_arcache  (s_axi_arcache),
        .s_axi_arprot   (s_axi_arprot),
        .s_axi_arqos    (s_axi_arqos),
        .s_axi_arregion (s_axi_arregion),

        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rready   (s_axi_rready),
        .s_axi_rdata    (s_axi_rdata),
        .s_axi_rresp    (s_axi_rresp),
        .s_axi_rid      (s_axi_rid),
        .s_axi_rlast    (s_axi_rlast),

        .EMU_HOST_CLK       (host_clk),
        .EMU_HOST_RST       (host_rst),
        .EMU_FF_SE          (ff_scan),
        .EMU_FF_DI          (ff_dir ? ff_sdi : ff_sdo),
        .EMU_FF_DO          (ff_sdo),
        .EMU_RAM_SR         (ram_scan_reset),
        .EMU_RAM_SE         (ram_scan),
        .EMU_RAM_SD         (ram_dir),
        .EMU_RAM_DI         (ram_sdi),
        .EMU_RAM_DO         (ram_sdo),
        .EMU_PORT_reset_imp_user_rst    (target_rst),
        .EMU_RUN_MODE       (run_mode),
        .EMU_SCAN_MODE      (scan_mode),
        .EMU_IDLE           (idle),
        `AXI4_CONNECT       (EMU_AXI_u_rammodel_backend_host_axi, m_axi)
    );

    // Note: EMU_PORT_clock_user_clk is not driven, so we create target_clk from EMU_PORT_clock_user_clk_FF
    ClockGate target_clk_gate (
        .CLK(emu_dut.EMU_PORT_clock_user_clk_FF),
        .EN(!ff_scan),
        .OCLK(target_clk)
    );

endmodule
