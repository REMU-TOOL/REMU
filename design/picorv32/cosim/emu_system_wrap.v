`timescale 1 ns / 1 ns

module emu_system_wrap(
    input           host_clk,
    input           host_rst,

    input           mmio_arvalid,
    output          mmio_arready,
    input   [31:0]  mmio_araddr,
    input   [2:0]   mmio_arprot,
    output          mmio_rvalid,
    input           mmio_rready,
    output  [1:0]   mmio_rresp,
    output  [31:0]  mmio_rdata,
    input           mmio_awvalid,
    output          mmio_awready,
    input   [31:0]  mmio_awaddr,
    input   [2:0]   mmio_awprot,
    input           mmio_wvalid,
    output          mmio_wready,
    input   [31:0]  mmio_wdata,
    input   [3:0]   mmio_wstrb,
    output          mmio_bvalid,
    input           mmio_bready,
    output  [1:0]   mmio_bresp,

    output          mem_awvalid,
    input           mem_awready,
    output  [31:0]  mem_awaddr,
    output  [0:0]   mem_awid,
    output  [7:0]   mem_awlen,
    output  [2:0]   mem_awsize,
    output  [1:0]   mem_awburst,
    output  [0:0]   mem_awlock,
    output  [3:0]   mem_awcache,
    output  [2:0]   mem_awprot,
    output  [3:0]   mem_awqos,
    output          mem_wvalid,
    input           mem_wready,
    output  [31:0]  mem_wdata,
    output  [3:0]   mem_wstrb,
    output          mem_wlast,
    input           mem_bvalid,
    output          mem_bready,
    input   [1:0]   mem_bresp,
    input   [0:0]   mem_bid,
    output          mem_arvalid,
    input           mem_arready,
    output  [31:0]  mem_araddr,
    output  [0:0]   mem_arid,
    output  [7:0]   mem_arlen,
    output  [2:0]   mem_arsize,
    output  [1:0]   mem_arburst,
    output  [0:0]   mem_arlock,
    output  [3:0]   mem_arcache,
    output  [2:0]   mem_arprot,
    output  [3:0]   mem_arqos,
    input           mem_rvalid,
    output          mem_rready,
    input   [31:0]  mem_rdata,
    input   [1:0]   mem_rresp,
    input   [0:0]   mem_rid,
    input           mem_rlast
);

    wire            scan_dma_awvalid;
    wire            scan_dma_awready;
    wire [39:0]     scan_dma_awaddr;
    wire [0:0]      scan_dma_awid = 1'b0;
    wire [7:0]      scan_dma_awlen;
    wire [2:0]      scan_dma_awsize;
    wire [1:0]      scan_dma_awburst;
    wire [0:0]      scan_dma_awlock;
    wire [3:0]      scan_dma_awcache;
    wire [2:0]      scan_dma_awprot;
    wire [3:0]      scan_dma_awqos;
    wire            scan_dma_wvalid;
    wire            scan_dma_wready;
    wire [63:0]     scan_dma_wdata;
    wire [7:0]      scan_dma_wstrb;
    wire            scan_dma_wlast;
    wire            scan_dma_bvalid;
    wire            scan_dma_bready;
    wire [1:0]      scan_dma_bresp;
    wire [0:0]      scan_dma_bid;
    wire            scan_dma_arvalid;
    wire            scan_dma_arready;
    wire [39:0]     scan_dma_araddr;
    wire [0:0]      scan_dma_arid = 1'b0;
    wire [7:0]      scan_dma_arlen;
    wire [2:0]      scan_dma_arsize;
    wire [1:0]      scan_dma_arburst;
    wire [0:0]      scan_dma_arlock;
    wire [3:0]      scan_dma_arcache;
    wire [2:0]      scan_dma_arprot;
    wire [3:0]      scan_dma_arqos;
    wire            scan_dma_rvalid;
    wire            scan_dma_rready;
    wire [63:0]     scan_dma_rdata;
    wire [1:0]      scan_dma_rresp;
    wire [0:0]      scan_dma_rid;
    wire            scan_dma_rlast;

    wire            scan_dma_conv_awvalid;
    wire            scan_dma_conv_awready;
    wire [31:0]     scan_dma_conv_awaddr;
    wire [0:0]      scan_dma_conv_awid;
    wire [7:0]      scan_dma_conv_awlen;
    wire [2:0]      scan_dma_conv_awsize;
    wire [1:0]      scan_dma_conv_awburst;
    wire [0:0]      scan_dma_conv_awlock;
    wire [3:0]      scan_dma_conv_awcache;
    wire [2:0]      scan_dma_conv_awprot;
    wire [3:0]      scan_dma_conv_awqos;
    wire            scan_dma_conv_wvalid;
    wire            scan_dma_conv_wready;
    wire [31:0]     scan_dma_conv_wdata;
    wire [3:0]      scan_dma_conv_wstrb;
    wire            scan_dma_conv_wlast;
    wire            scan_dma_conv_bvalid;
    wire            scan_dma_conv_bready;
    wire [1:0]      scan_dma_conv_bresp;
    wire [0:0]      scan_dma_conv_bid;
    wire            scan_dma_conv_arvalid;
    wire            scan_dma_conv_arready;
    wire [31:0]     scan_dma_conv_araddr;
    wire [0:0]      scan_dma_conv_arid;
    wire [7:0]      scan_dma_conv_arlen;
    wire [2:0]      scan_dma_conv_arsize;
    wire [1:0]      scan_dma_conv_arburst;
    wire [0:0]      scan_dma_conv_arlock;
    wire [3:0]      scan_dma_conv_arcache;
    wire [2:0]      scan_dma_conv_arprot;
    wire [3:0]      scan_dma_conv_arqos;
    wire            scan_dma_conv_rvalid;
    wire            scan_dma_conv_rready;
    wire [31:0]     scan_dma_conv_rdata;
    wire [1:0]      scan_dma_conv_rresp;
    wire [0:0]      scan_dma_conv_rid;
    wire            scan_dma_conv_rlast;

    wire            rammodel_awvalid;
    wire            rammodel_awready;
    wire [31:0]     rammodel_awaddr;
    wire [0:0]      rammodel_awid;
    wire [7:0]      rammodel_awlen;
    wire [2:0]      rammodel_awsize;
    wire [1:0]      rammodel_awburst;
    wire [0:0]      rammodel_awlock;
    wire [3:0]      rammodel_awcache;
    wire [2:0]      rammodel_awprot;
    wire [3:0]      rammodel_awqos;
    wire            rammodel_wvalid;
    wire            rammodel_wready;
    wire [31:0]     rammodel_wdata;
    wire [3:0]      rammodel_wstrb;
    wire            rammodel_wlast;
    wire            rammodel_bvalid;
    wire            rammodel_bready;
    wire [1:0]      rammodel_bresp;
    wire [0:0]      rammodel_bid;
    wire            rammodel_arvalid;
    wire            rammodel_arready;
    wire [31:0]     rammodel_araddr;
    wire [0:0]      rammodel_arid;
    wire [7:0]      rammodel_arlen;
    wire [2:0]      rammodel_arsize;
    wire [1:0]      rammodel_arburst;
    wire [0:0]      rammodel_arlock;
    wire [3:0]      rammodel_arcache;
    wire [2:0]      rammodel_arprot;
    wire [3:0]      rammodel_arqos;
    wire            rammodel_rvalid;
    wire            rammodel_rready;
    wire [31:0]     rammodel_rdata;
    wire [1:0]      rammodel_rresp;
    wire [0:0]      rammodel_rid;
    wire            rammodel_rlast;

    EMU_SYSTEM u_emu_system(
        .EMU_HOST_CLK                                   (host_clk),
        .EMU_HOST_RST                                   (host_rst),

        .EMU_CTRL_arvalid                               (mmio_arvalid),
        .EMU_CTRL_arready                               (mmio_arready),
        .EMU_CTRL_araddr                                (mmio_araddr[15:0]),
        .EMU_CTRL_arprot                                (mmio_arprot),
        .EMU_CTRL_rvalid                                (mmio_rvalid),
        .EMU_CTRL_rready                                (mmio_rready),
        .EMU_CTRL_rresp                                 (mmio_rresp),
        .EMU_CTRL_rdata                                 (mmio_rdata),
        .EMU_CTRL_awvalid                               (mmio_awvalid),
        .EMU_CTRL_awready                               (mmio_awready),
        .EMU_CTRL_awaddr                                (mmio_awaddr[15:0]),
        .EMU_CTRL_awprot                                (mmio_awprot),
        .EMU_CTRL_wvalid                                (mmio_wvalid),
        .EMU_CTRL_wready                                (mmio_wready),
        .EMU_CTRL_wdata                                 (mmio_wdata),
        .EMU_CTRL_wstrb                                 (mmio_wstrb),
        .EMU_CTRL_bvalid                                (mmio_bvalid),
        .EMU_CTRL_bready                                (mmio_bready),
        .EMU_CTRL_bresp                                 (mmio_bresp),

        .EMU_SCAN_DMA_AXI_arvalid                       (scan_dma_arvalid),
        .EMU_SCAN_DMA_AXI_arready                       (scan_dma_arready),
        .EMU_SCAN_DMA_AXI_araddr                        (scan_dma_araddr),
        .EMU_SCAN_DMA_AXI_arprot                        (scan_dma_arprot),
        .EMU_SCAN_DMA_AXI_arlen                         (scan_dma_arlen),
        .EMU_SCAN_DMA_AXI_arsize                        (scan_dma_arsize),
        .EMU_SCAN_DMA_AXI_arburst                       (scan_dma_arburst),
        .EMU_SCAN_DMA_AXI_arlock                        (scan_dma_arlock),
        .EMU_SCAN_DMA_AXI_arcache                       (scan_dma_arcache),
        .EMU_SCAN_DMA_AXI_rvalid                        (scan_dma_rvalid),
        .EMU_SCAN_DMA_AXI_rready                        (scan_dma_rready),
        .EMU_SCAN_DMA_AXI_rresp                         (scan_dma_rresp),
        .EMU_SCAN_DMA_AXI_rdata                         (scan_dma_rdata),
        .EMU_SCAN_DMA_AXI_rlast                         (scan_dma_rlast),
        .EMU_SCAN_DMA_AXI_awvalid                       (scan_dma_awvalid),
        .EMU_SCAN_DMA_AXI_awready                       (scan_dma_awready),
        .EMU_SCAN_DMA_AXI_awaddr                        (scan_dma_awaddr),
        .EMU_SCAN_DMA_AXI_awprot                        (scan_dma_awprot),
        .EMU_SCAN_DMA_AXI_awlen                         (scan_dma_awlen),
        .EMU_SCAN_DMA_AXI_awsize                        (scan_dma_awsize),
        .EMU_SCAN_DMA_AXI_awburst                       (scan_dma_awburst),
        .EMU_SCAN_DMA_AXI_awlock                        (scan_dma_awlock),
        .EMU_SCAN_DMA_AXI_awcache                       (scan_dma_awcache),
        .EMU_SCAN_DMA_AXI_wvalid                        (scan_dma_wvalid),
        .EMU_SCAN_DMA_AXI_wready                        (scan_dma_wready),
        .EMU_SCAN_DMA_AXI_wdata                         (scan_dma_wdata),
        .EMU_SCAN_DMA_AXI_wstrb                         (scan_dma_wstrb),
        .EMU_SCAN_DMA_AXI_wlast                         (scan_dma_wlast),
        .EMU_SCAN_DMA_AXI_bvalid                        (scan_dma_bvalid),
        .EMU_SCAN_DMA_AXI_bready                        (scan_dma_bready),
        .EMU_SCAN_DMA_AXI_bresp                         (scan_dma_bresp),

        .EMU_AXI_u_rammodel_backend_host_axi_arvalid    (rammodel_arvalid),
        .EMU_AXI_u_rammodel_backend_host_axi_arready    (rammodel_arready),
        .EMU_AXI_u_rammodel_backend_host_axi_araddr     (rammodel_araddr),
        .EMU_AXI_u_rammodel_backend_host_axi_arid       (rammodel_arid),
        .EMU_AXI_u_rammodel_backend_host_axi_arprot     (rammodel_arprot),
        .EMU_AXI_u_rammodel_backend_host_axi_arlen      (rammodel_arlen),
        .EMU_AXI_u_rammodel_backend_host_axi_arsize     (rammodel_arsize),
        .EMU_AXI_u_rammodel_backend_host_axi_arburst    (rammodel_arburst),
        .EMU_AXI_u_rammodel_backend_host_axi_arlock     (rammodel_arlock),
        .EMU_AXI_u_rammodel_backend_host_axi_arcache    (rammodel_arcache),
        .EMU_AXI_u_rammodel_backend_host_axi_rvalid     (rammodel_rvalid),
        .EMU_AXI_u_rammodel_backend_host_axi_rready     (rammodel_rready),
        .EMU_AXI_u_rammodel_backend_host_axi_rid        (rammodel_rid),
        .EMU_AXI_u_rammodel_backend_host_axi_rresp      (rammodel_rresp),
        .EMU_AXI_u_rammodel_backend_host_axi_rdata      (rammodel_rdata),
        .EMU_AXI_u_rammodel_backend_host_axi_rlast      (rammodel_rlast),
        .EMU_AXI_u_rammodel_backend_host_axi_awvalid    (rammodel_awvalid),
        .EMU_AXI_u_rammodel_backend_host_axi_awready    (rammodel_awready),
        .EMU_AXI_u_rammodel_backend_host_axi_awaddr     (rammodel_awaddr),
        .EMU_AXI_u_rammodel_backend_host_axi_awid       (rammodel_awid),
        .EMU_AXI_u_rammodel_backend_host_axi_awprot     (rammodel_awprot),
        .EMU_AXI_u_rammodel_backend_host_axi_awlen      (rammodel_awlen),
        .EMU_AXI_u_rammodel_backend_host_axi_awsize     (rammodel_awsize),
        .EMU_AXI_u_rammodel_backend_host_axi_awburst    (rammodel_awburst),
        .EMU_AXI_u_rammodel_backend_host_axi_awlock     (rammodel_awlock),
        .EMU_AXI_u_rammodel_backend_host_axi_awcache    (rammodel_awcache),
        .EMU_AXI_u_rammodel_backend_host_axi_wvalid     (rammodel_wvalid),
        .EMU_AXI_u_rammodel_backend_host_axi_wready     (rammodel_wready),
        .EMU_AXI_u_rammodel_backend_host_axi_wdata      (rammodel_wdata),
        .EMU_AXI_u_rammodel_backend_host_axi_wstrb      (rammodel_wstrb),
        .EMU_AXI_u_rammodel_backend_host_axi_wlast      (rammodel_wlast),
        .EMU_AXI_u_rammodel_backend_host_axi_bvalid     (rammodel_bvalid),
        .EMU_AXI_u_rammodel_backend_host_axi_bready     (rammodel_bready),
        .EMU_AXI_u_rammodel_backend_host_axi_bid        (rammodel_bid),
        .EMU_AXI_u_rammodel_backend_host_axi_bresp      (rammodel_bresp)
    );

    axi_adapter #(
        .ADDR_WIDTH     (32),
        .S_DATA_WIDTH   (64),
        .M_DATA_WIDTH   (32),
        .ID_WIDTH       (1)
    ) scan_dma_adapter (
        .clk            (host_clk),
        .rst            (host_rst),

        .s_axi_awid     (scan_dma_awid),
        .s_axi_awaddr   (scan_dma_awaddr[31:0]),
        .s_axi_awlen    (scan_dma_awlen),
        .s_axi_awsize   (scan_dma_awsize),
        .s_axi_awburst  (scan_dma_awburst),
        .s_axi_awlock   (scan_dma_awlock),
        .s_axi_awcache  (scan_dma_awcache),
        .s_axi_awprot   (scan_dma_awprot),
        .s_axi_awqos    (scan_dma_awqos),
        .s_axi_awuser   (scan_dma_awuser),
        .s_axi_awvalid  (scan_dma_awvalid),
        .s_axi_awready  (scan_dma_awready),
        .s_axi_wdata    (scan_dma_wdata),
        .s_axi_wstrb    (scan_dma_wstrb),
        .s_axi_wlast    (scan_dma_wlast),
        .s_axi_wuser    (scan_dma_wuser),
        .s_axi_wvalid   (scan_dma_wvalid),
        .s_axi_wready   (scan_dma_wready),
        .s_axi_bid      (scan_dma_bid),
        .s_axi_bresp    (scan_dma_bresp),
        .s_axi_buser    (scan_dma_buser),
        .s_axi_bvalid   (scan_dma_bvalid),
        .s_axi_bready   (scan_dma_bready),
        .s_axi_arid     (scan_dma_arid),
        .s_axi_araddr   (scan_dma_araddr[31:0]),
        .s_axi_arlen    (scan_dma_arlen),
        .s_axi_arsize   (scan_dma_arsize),
        .s_axi_arburst  (scan_dma_arburst),
        .s_axi_arlock   (scan_dma_arlock),
        .s_axi_arcache  (scan_dma_arcache),
        .s_axi_arprot   (scan_dma_arprot),
        .s_axi_arqos    (scan_dma_arqos),
        .s_axi_aruser   (scan_dma_aruser),
        .s_axi_arvalid  (scan_dma_arvalid),
        .s_axi_arready  (scan_dma_arready),
        .s_axi_rid      (scan_dma_rid),
        .s_axi_rdata    (scan_dma_rdata),
        .s_axi_rresp    (scan_dma_rresp),
        .s_axi_rlast    (scan_dma_rlast),
        .s_axi_ruser    (scan_dma_ruser),
        .s_axi_rvalid   (scan_dma_rvalid),
        .s_axi_rready   (scan_dma_rready),

        .m_axi_awid     (scan_dma_conv_awid),
        .m_axi_awaddr   (scan_dma_conv_awaddr),
        .m_axi_awlen    (scan_dma_conv_awlen),
        .m_axi_awsize   (scan_dma_conv_awsize),
        .m_axi_awburst  (scan_dma_conv_awburst),
        .m_axi_awlock   (scan_dma_conv_awlock),
        .m_axi_awcache  (scan_dma_conv_awcache),
        .m_axi_awprot   (scan_dma_conv_awprot),
        .m_axi_awqos    (scan_dma_conv_awqos),
        .m_axi_awuser   (scan_dma_conv_awuser),
        .m_axi_awvalid  (scan_dma_conv_awvalid),
        .m_axi_awready  (scan_dma_conv_awready),
        .m_axi_wdata    (scan_dma_conv_wdata),
        .m_axi_wstrb    (scan_dma_conv_wstrb),
        .m_axi_wlast    (scan_dma_conv_wlast),
        .m_axi_wuser    (scan_dma_conv_wuser),
        .m_axi_wvalid   (scan_dma_conv_wvalid),
        .m_axi_wready   (scan_dma_conv_wready),
        .m_axi_bid      (scan_dma_conv_bid),
        .m_axi_bresp    (scan_dma_conv_bresp),
        .m_axi_buser    (scan_dma_conv_buser),
        .m_axi_bvalid   (scan_dma_conv_bvalid),
        .m_axi_bready   (scan_dma_conv_bready),
        .m_axi_arid     (scan_dma_conv_arid),
        .m_axi_araddr   (scan_dma_conv_araddr),
        .m_axi_arlen    (scan_dma_conv_arlen),
        .m_axi_arsize   (scan_dma_conv_arsize),
        .m_axi_arburst  (scan_dma_conv_arburst),
        .m_axi_arlock   (scan_dma_conv_arlock),
        .m_axi_arcache  (scan_dma_conv_arcache),
        .m_axi_arprot   (scan_dma_conv_arprot),
        .m_axi_arqos    (scan_dma_conv_arqos),
        .m_axi_aruser   (scan_dma_conv_aruser),
        .m_axi_arvalid  (scan_dma_conv_arvalid),
        .m_axi_arready  (scan_dma_conv_arready),
        .m_axi_rid      (scan_dma_conv_rid),
        .m_axi_rdata    (scan_dma_conv_rdata),
        .m_axi_rresp    (scan_dma_conv_rresp),
        .m_axi_rlast    (scan_dma_conv_rlast),
        .m_axi_ruser    (scan_dma_conv_ruser),
        .m_axi_rvalid   (scan_dma_conv_rvalid),
        .m_axi_rready   (scan_dma_conv_rready)
    );

    axi_interconnect_wrap_2x1 #(
        .DATA_WIDTH     (32),
        .ADDR_WIDTH     (32),
        .ID_WIDTH       (1),
        .M00_BASE_ADDR  ('h00000000),
        .M00_ADDR_WIDTH (32)
    ) mem_xbar (
        .clk            (host_clk),
        .rst            (host_rst),

        .s00_axi_awid   (scan_dma_conv_awid),
        .s00_axi_awaddr (scan_dma_conv_awaddr),
        .s00_axi_awlen  (scan_dma_conv_awlen),
        .s00_axi_awsize (scan_dma_conv_awsize),
        .s00_axi_awburst(scan_dma_conv_awburst),
        .s00_axi_awlock (scan_dma_conv_awlock),
        .s00_axi_awcache(scan_dma_conv_awcache),
        .s00_axi_awprot (scan_dma_conv_awprot),
        .s00_axi_awqos  (scan_dma_conv_awqos),
        .s00_axi_awuser (scan_dma_conv_awuser),
        .s00_axi_awvalid(scan_dma_conv_awvalid),
        .s00_axi_awready(scan_dma_conv_awready),
        .s00_axi_wdata  (scan_dma_conv_wdata),
        .s00_axi_wstrb  (scan_dma_conv_wstrb),
        .s00_axi_wlast  (scan_dma_conv_wlast),
        .s00_axi_wuser  (scan_dma_conv_wuser),
        .s00_axi_wvalid (scan_dma_conv_wvalid),
        .s00_axi_wready (scan_dma_conv_wready),
        .s00_axi_bid    (scan_dma_conv_bid),
        .s00_axi_bresp  (scan_dma_conv_bresp),
        .s00_axi_buser  (scan_dma_conv_buser),
        .s00_axi_bvalid (scan_dma_conv_bvalid),
        .s00_axi_bready (scan_dma_conv_bready),
        .s00_axi_arid   (scan_dma_conv_arid),
        .s00_axi_araddr (scan_dma_conv_araddr),
        .s00_axi_arlen  (scan_dma_conv_arlen),
        .s00_axi_arsize (scan_dma_conv_arsize),
        .s00_axi_arburst(scan_dma_conv_arburst),
        .s00_axi_arlock (scan_dma_conv_arlock),
        .s00_axi_arcache(scan_dma_conv_arcache),
        .s00_axi_arprot (scan_dma_conv_arprot),
        .s00_axi_arqos  (scan_dma_conv_arqos),
        .s00_axi_aruser (scan_dma_conv_aruser),
        .s00_axi_arvalid(scan_dma_conv_arvalid),
        .s00_axi_arready(scan_dma_conv_arready),
        .s00_axi_rid    (scan_dma_conv_rid),
        .s00_axi_rdata  (scan_dma_conv_rdata),
        .s00_axi_rresp  (scan_dma_conv_rresp),
        .s00_axi_rlast  (scan_dma_conv_rlast),
        .s00_axi_ruser  (scan_dma_conv_ruser),
        .s00_axi_rvalid (scan_dma_conv_rvalid),
        .s00_axi_rready (scan_dma_conv_rready),

        .s01_axi_awid   (rammodel_awid),
        .s01_axi_awaddr (rammodel_awaddr),
        .s01_axi_awlen  (rammodel_awlen),
        .s01_axi_awsize (rammodel_awsize),
        .s01_axi_awburst(rammodel_awburst),
        .s01_axi_awlock (rammodel_awlock),
        .s01_axi_awcache(rammodel_awcache),
        .s01_axi_awprot (rammodel_awprot),
        .s01_axi_awqos  (rammodel_awqos),
        .s01_axi_awuser (rammodel_awuser),
        .s01_axi_awvalid(rammodel_awvalid),
        .s01_axi_awready(rammodel_awready),
        .s01_axi_wdata  (rammodel_wdata),
        .s01_axi_wstrb  (rammodel_wstrb),
        .s01_axi_wlast  (rammodel_wlast),
        .s01_axi_wuser  (rammodel_wuser),
        .s01_axi_wvalid (rammodel_wvalid),
        .s01_axi_wready (rammodel_wready),
        .s01_axi_bid    (rammodel_bid),
        .s01_axi_bresp  (rammodel_bresp),
        .s01_axi_buser  (rammodel_buser),
        .s01_axi_bvalid (rammodel_bvalid),
        .s01_axi_bready (rammodel_bready),
        .s01_axi_arid   (rammodel_arid),
        .s01_axi_araddr (rammodel_araddr),
        .s01_axi_arlen  (rammodel_arlen),
        .s01_axi_arsize (rammodel_arsize),
        .s01_axi_arburst(rammodel_arburst),
        .s01_axi_arlock (rammodel_arlock),
        .s01_axi_arcache(rammodel_arcache),
        .s01_axi_arprot (rammodel_arprot),
        .s01_axi_arqos  (rammodel_arqos),
        .s01_axi_aruser (rammodel_aruser),
        .s01_axi_arvalid(rammodel_arvalid),
        .s01_axi_arready(rammodel_arready),
        .s01_axi_rid    (rammodel_rid),
        .s01_axi_rdata  (rammodel_rdata),
        .s01_axi_rresp  (rammodel_rresp),
        .s01_axi_rlast  (rammodel_rlast),
        .s01_axi_ruser  (rammodel_ruser),
        .s01_axi_rvalid (rammodel_rvalid),
        .s01_axi_rready (rammodel_rready),

        .m00_axi_awid   (mem_awid),
        .m00_axi_awaddr (mem_awaddr),
        .m00_axi_awlen  (mem_awlen),
        .m00_axi_awsize (mem_awsize),
        .m00_axi_awburst(mem_awburst),
        .m00_axi_awlock (mem_awlock),
        .m00_axi_awcache(mem_awcache),
        .m00_axi_awprot (mem_awprot),
        .m00_axi_awqos  (mem_awqos),
        .m00_axi_awuser (mem_awuser),
        .m00_axi_awvalid(mem_awvalid),
        .m00_axi_awready(mem_awready),
        .m00_axi_wdata  (mem_wdata),
        .m00_axi_wstrb  (mem_wstrb),
        .m00_axi_wlast  (mem_wlast),
        .m00_axi_wuser  (mem_wuser),
        .m00_axi_wvalid (mem_wvalid),
        .m00_axi_wready (mem_wready),
        .m00_axi_bid    (mem_bid),
        .m00_axi_bresp  (mem_bresp),
        .m00_axi_buser  (mem_buser),
        .m00_axi_bvalid (mem_bvalid),
        .m00_axi_bready (mem_bready),
        .m00_axi_arid   (mem_arid),
        .m00_axi_araddr (mem_araddr),
        .m00_axi_arlen  (mem_arlen),
        .m00_axi_arsize (mem_arsize),
        .m00_axi_arburst(mem_arburst),
        .m00_axi_arlock (mem_arlock),
        .m00_axi_arcache(mem_arcache),
        .m00_axi_arprot (mem_arprot),
        .m00_axi_arqos  (mem_arqos),
        .m00_axi_aruser (mem_aruser),
        .m00_axi_arvalid(mem_arvalid),
        .m00_axi_arready(mem_arready),
        .m00_axi_rid    (mem_rid),
        .m00_axi_rdata  (mem_rdata),
        .m00_axi_rresp  (mem_rresp),
        .m00_axi_rlast  (mem_rlast),
        .m00_axi_ruser  (mem_ruser),
        .m00_axi_rvalid (mem_rvalid),
        .m00_axi_rready (mem_rready)
    );

endmodule
