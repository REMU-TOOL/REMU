`timescale 1ns / 1ps

`include "axi.vh"

module test #(
    // DO NOT CHANGE
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input                       clk,
    input                       resetn,

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
    input                       ram_scan,
    input                       ram_dir,
    input   [63:0]              ram_sdi,
    output  [63:0]              ram_sdo,

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down,

    // for testbench use
    output                      dut_clk

);

    //reg clk = 0, rst = 1;
    wire rst = !resetn;
    //reg pause = 0;
    //reg ff_scan = 0, ff_dir = 0;
    //reg [63:0] ff_sdi = 0;
    //wire [63:0] ff_sdo;
    //reg ram_scan = 0, ram_dir = 0;
    //reg [63:0] ram_sdi = 0;
    //wire [63:0] ram_sdo;

    wire dut_stall;

    wire dut_clk, dut_clk_en;
    ClockGate clk_gate(
        .CLK(clk),
        .EN(dut_clk_en),
        .GCLK(dut_clk)
    );

    wire emu_dut_ff_clk, emu_dut_ff_clk_en;
    ClockGate dut_ff_clk_gate(
        .CLK(clk),
        .EN(emu_dut_ff_clk_en),
        .GCLK(emu_dut_ff_clk)
    );

    wire emu_dut_ram_clk, emu_dut_ram_clk_en;
    ClockGate dut_ram_clk_gate(
        .CLK(clk),
        .EN(emu_dut_ram_clk_en),
        .GCLK(emu_dut_ram_clk)
    );

    EMU_DUT emu_dut(

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

        .emu_clk            (clk),
        .emu_rst            (rst),
        .emu_ff_se          (ff_scan),
        .emu_ff_di          (ff_dir ? ff_sdi : ff_sdo),
        .emu_ff_do          (ff_sdo),
        .emu_ram_se         (ram_scan),
        .emu_ram_sd         (ram_dir),
        .emu_ram_di         (ram_sdi),
        .emu_ram_do         (ram_sdo),
        .emu_dut_ff_clk     (emu_dut_ff_clk),
        .emu_dut_ram_clk    (emu_dut_ram_clk),
        .emu_dut_rst        (rst),
        .emu_dut_trig       (),
        .emu_stall          (pause || dut_stall),
        .emu_stall_gen      (dut_stall),
        .emu_up_req         (up_req),
        .emu_down_req       (down_req),
        .emu_up_stat        (up),
        .emu_down_stat      (down),
        `AXI4_CONNECT       (emu_auto_0_dram, m_axi)
    );

    assign dut_clk_en = !pause && !dut_stall;
    assign emu_dut_ff_clk_en = !pause && !dut_stall || ff_scan;
    assign emu_dut_ram_clk_en = !pause && !dut_stall || ram_scan;

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile(`DUMPFILE);
            $dumpvars();
        end
    end

endmodule
