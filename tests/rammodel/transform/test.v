`timescale 1ns / 1ps

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

        .EMU_CLK            (clk),
        .EMU_FF_SE          (ff_scan),
        .EMU_FF_DI          (ff_dir ? ff_sdi : ff_sdo),
        .EMU_FF_DO          (ff_sdo),
        .EMU_RAM_SE         (ram_scan),
        .EMU_RAM_SD         (ram_dir),
        .EMU_RAM_DI         (ram_sdi),
        .EMU_RAM_DO         (ram_sdo),
        .EMU_DUT_FF_CLK     (emu_dut_ff_clk),
        .EMU_DUT_RAM_CLK    (emu_dut_ram_clk),
        .EMU_DUT_RST        (rst),
        .EMU_DUT_TRIG       (),
        .EMU_INTERNAL_CLOCK             (clk),
        .EMU_INTERNAL_RESET             (rst),
        .EMU_INTERNAL_PAUSE             (pause),
        .EMU_INTERNAL_UP_REQ            (up_req),
        .EMU_INTERNAL_DOWN_REQ          (down_req),
        .EMU_INTERNAL_UP_STAT           (up),
        .EMU_INTERNAL_DOWN_STAT         (down),
        .EMU_INTERNAL_STALL             (dut_stall),
        .EMU_INTERNAL_DRAM_AWVALID      (m_axi_awvalid),
        .EMU_INTERNAL_DRAM_AWREADY      (m_axi_awready),
        .EMU_INTERNAL_DRAM_AWADDR       (m_axi_awaddr),
        .EMU_INTERNAL_DRAM_AWID         (m_axi_awid),
        .EMU_INTERNAL_DRAM_AWLEN        (m_axi_awlen),
        .EMU_INTERNAL_DRAM_AWSIZE       (m_axi_awsize),
        .EMU_INTERNAL_DRAM_AWBURST      (m_axi_awburst),
        .EMU_INTERNAL_DRAM_WVALID       (m_axi_wvalid),
        .EMU_INTERNAL_DRAM_WREADY       (m_axi_wready),
        .EMU_INTERNAL_DRAM_WDATA        (m_axi_wdata),
        .EMU_INTERNAL_DRAM_WSTRB        (m_axi_wstrb),
        .EMU_INTERNAL_DRAM_WLAST        (m_axi_wlast),
        .EMU_INTERNAL_DRAM_BVALID       (m_axi_bvalid),
        .EMU_INTERNAL_DRAM_BREADY       (m_axi_bready),
        .EMU_INTERNAL_DRAM_BID          (m_axi_bid),
        .EMU_INTERNAL_DRAM_ARVALID      (m_axi_arvalid),
        .EMU_INTERNAL_DRAM_ARREADY      (m_axi_arready),
        .EMU_INTERNAL_DRAM_ARADDR       (m_axi_araddr),
        .EMU_INTERNAL_DRAM_ARID         (m_axi_arid),
        .EMU_INTERNAL_DRAM_ARLEN        (m_axi_arlen),
        .EMU_INTERNAL_DRAM_ARSIZE       (m_axi_arsize),
        .EMU_INTERNAL_DRAM_ARBURST      (m_axi_arburst),
        .EMU_INTERNAL_DRAM_RVALID       (m_axi_rvalid),
        .EMU_INTERNAL_DRAM_RREADY       (m_axi_rready),
        .EMU_INTERNAL_DRAM_RDATA        (m_axi_rdata),
        .EMU_INTERNAL_DRAM_RID          (m_axi_rid),
        .EMU_INTERNAL_DRAM_RLAST        (m_axi_rlast)
    );

    assign m_axi_awlock        = 1'd0;
    assign m_axi_awcache       = 4'd0;
    assign m_axi_awprot        = 3'b010;
    assign m_axi_awqos         = 4'd0;
    assign m_axi_awregion      = 4'd0;
    assign m_axi_arlock        = 1'd0;
    assign m_axi_arcache       = 4'd0;
    assign m_axi_arprot        = 3'b010;
    assign m_axi_arqos         = 4'd0;
    assign m_axi_arregion      = 4'd0;

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
