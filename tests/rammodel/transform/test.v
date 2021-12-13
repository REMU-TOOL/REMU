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

        .\$EMU$CLK          (clk),
        .\$EMU$FF$SE        (ff_scan),
        .\$EMU$FF$DI        (ff_dir ? ff_sdi : ff_sdo),
        .\$EMU$FF$DO        (ff_sdo),
        .\$EMU$RAM$SE       (ram_scan),
        .\$EMU$RAM$SD       (ram_dir),
        .\$EMU$RAM$DI       (ram_sdi),
        .\$EMU$RAM$DO       (ram_sdo),
        .\$EMU$DUT$FF$CLK   (emu_dut_ff_clk),
        .\$EMU$DUT$RAM$CLK  (emu_dut_ram_clk),
        .\$EMU$DUT$RST      (rst),
        .\$EMU$DUT$TRIG     (),
        .\$EMU$INTERNAL$CLOCK           (clk),
        .\$EMU$INTERNAL$RESET           (rst),
        .\$EMU$INTERNAL$PAUSE           (pause),
        .\$EMU$INTERNAL$UP_REQ          (up_req),
        .\$EMU$INTERNAL$DOWN_REQ        (down_req),
        .\$EMU$INTERNAL$UP_STAT         (up),
        .\$EMU$INTERNAL$DOWN_STAT       (down),
        .\$EMU$INTERNAL$STALL           (dut_stall),
        .\$EMU$INTERNAL$DRAM_AWVALID    (m_axi_awvalid),
        .\$EMU$INTERNAL$DRAM_AWREADY    (m_axi_awready),
        .\$EMU$INTERNAL$DRAM_AWADDR     (m_axi_awaddr),
        .\$EMU$INTERNAL$DRAM_AWID       (m_axi_awid),
        .\$EMU$INTERNAL$DRAM_AWLEN      (m_axi_awlen),
        .\$EMU$INTERNAL$DRAM_AWSIZE     (m_axi_awsize),
        .\$EMU$INTERNAL$DRAM_AWBURST    (m_axi_awburst),
        .\$EMU$INTERNAL$DRAM_WVALID     (m_axi_wvalid),
        .\$EMU$INTERNAL$DRAM_WREADY     (m_axi_wready),
        .\$EMU$INTERNAL$DRAM_WDATA      (m_axi_wdata),
        .\$EMU$INTERNAL$DRAM_WSTRB      (m_axi_wstrb),
        .\$EMU$INTERNAL$DRAM_WLAST      (m_axi_wlast),
        .\$EMU$INTERNAL$DRAM_BVALID     (m_axi_bvalid),
        .\$EMU$INTERNAL$DRAM_BREADY     (m_axi_bready),
        .\$EMU$INTERNAL$DRAM_BID        (m_axi_bid),
        .\$EMU$INTERNAL$DRAM_ARVALID    (m_axi_arvalid),
        .\$EMU$INTERNAL$DRAM_ARREADY    (m_axi_arready),
        .\$EMU$INTERNAL$DRAM_ARADDR     (m_axi_araddr),
        .\$EMU$INTERNAL$DRAM_ARID       (m_axi_arid),
        .\$EMU$INTERNAL$DRAM_ARLEN      (m_axi_arlen),
        .\$EMU$INTERNAL$DRAM_ARSIZE     (m_axi_arsize),
        .\$EMU$INTERNAL$DRAM_ARBURST    (m_axi_arburst),
        .\$EMU$INTERNAL$DRAM_RVALID     (m_axi_rvalid),
        .\$EMU$INTERNAL$DRAM_RREADY     (m_axi_rready),
        .\$EMU$INTERNAL$DRAM_RDATA      (m_axi_rdata),
        .\$EMU$INTERNAL$DRAM_RID        (m_axi_rid),
        .\$EMU$INTERNAL$DRAM_RLAST      (m_axi_rlast)
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
