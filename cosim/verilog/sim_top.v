`timescale 1ns / 1ps

module sim_top;

    reg clk = 0, rst = 0;

    always #5 clk = ~clk;

    wire          mem_awready;
    wire          mem_awvalid;
    wire   [31:0] mem_awaddr;
    wire   [2:0]  mem_awprot;
    wire          mem_awid;
    wire          mem_awuser;
    wire   [7:0]  mem_awlen;
    wire   [2:0]  mem_awsize;
    wire   [1:0]  mem_awburst;
    wire          mem_awlock;
    wire   [3:0]  mem_awcache;
    wire   [3:0]  mem_awqos;
    wire          mem_wready;
    wire          mem_wvalid;
    wire   [63:0] mem_wdata;
    wire   [7:0]  mem_wstrb;
    wire          mem_wlast;
    wire          mem_bready;
    wire          mem_bvalid;
    wire   [1:0]  mem_bresp;
    wire          mem_bid;
    wire          mem_buser;
    wire          mem_arready;
    wire          mem_arvalid;
    wire   [31:0] mem_araddr;
    wire   [2:0]  mem_arprot;
    wire          mem_arid;
    wire          mem_aruser;
    wire   [7:0]  mem_arlen;
    wire   [2:0]  mem_arsize;
    wire   [1:0]  mem_arburst;
    wire          mem_arlock;
    wire   [3:0]  mem_arcache;
    wire   [3:0]  mem_arqos;
    wire          mem_rready;
    wire          mem_rvalid;
    wire   [1:0]  mem_rresp;
    wire   [63:0] mem_rdata;
    wire          mem_rlast;
    wire          mem_rid;
    wire          mem_ruser;

    wire          mmio_awready;
    wire          mmio_awvalid;
    wire   [31:0] mmio_awaddr;
    wire   [2:0]  mmio_awprot;
    wire          mmio_wready;
    wire          mmio_wvalid;
    wire   [31:0] mmio_wdata;
    wire   [3:0]  mmio_wstrb;
    wire          mmio_bready;
    wire          mmio_bvalid;
    wire   [1:0]  mmio_bresp;
    wire          mmio_arready;
    wire          mmio_arvalid;
    wire   [31:0] mmio_araddr;
    wire   [2:0]  mmio_arprot;
    wire          mmio_rready;
    wire          mmio_rvalid;
    wire   [1:0]  mmio_rresp;
    wire   [31:0] mmio_rdata;

    cosim_bfm_axi #(
        .AXI_WIDTH_ID   (1),
        .AXI_WIDTH_AD   (32),
        .AXI_WIDTH_DA   (64),
        .COSIM_CHAN_ID  (0),
        .COSIM_VERBOSE  (0)
    ) bfm_mem (
        .ARESETn    (!rst),
        .ACLK       (clk),
        .M_AWID     (mem_awid),
        .M_AWADDR   (mem_awaddr),
        .M_AWLEN    (mem_awlen),
        .M_AWLOCK   (mem_awlock),
        .M_AWSIZE   (mem_awsize),
        .M_AWBURST  (mem_awburst),
        .M_AWCACHE  (mem_awcache),
        .M_AWPROT   (mem_awprot),
        .M_AWVALID  (mem_awvalid),
        .M_AWREADY  (mem_awready),
        .M_AWQOS    (mem_awqos),
        .M_AWREGION (),
        .M_WDATA    (mem_wdata),
        .M_WSTRB    (mem_wstrb),
        .M_WLAST    (mem_wlast),
        .M_WVALID   (mem_wvalid),
        .M_WREADY   (mem_wready),
        .M_BID      (mem_bid),
        .M_BRESP    (mem_bresp),
        .M_BVALID   (mem_bvalid),
        .M_BREADY   (mem_bready),
        .M_ARID     (mem_arid),
        .M_ARADDR   (mem_araddr),
        .M_ARLEN    (mem_arlen),
        .M_ARLOCK   (mem_arlock),
        .M_ARSIZE   (mem_arsize),
        .M_ARBURST  (mem_arburst),
        .M_ARCACHE  (mem_arcache),
        .M_ARPROT   (mem_arprot),
        .M_ARVALID  (mem_arvalid),
        .M_ARREADY  (mem_arready),
        .M_ARQOS    (mem_arqos),
        .M_ARREGION (),
        .M_RID      (mem_rid),
        .M_RDATA    (mem_rdata),
        .M_RRESP    (mem_rresp),
        .M_RLAST    (mem_rlast),
        .M_RVALID   (mem_rvalid),
        .M_RREADY   (mem_rready)
    );

    cosim_bfm_axi #(
        .AXI_WIDTH_ID   (1),
        .AXI_WIDTH_AD   (32),
        .AXI_WIDTH_DA   (32),
        .COSIM_CHAN_ID  (1),
        .COSIM_VERBOSE  (0)
    ) bfm_mmio (
        .ARESETn    (!rst),
        .ACLK       (clk),
        .M_AWID     (),
        .M_AWADDR   (mmio_awaddr),
        .M_AWLEN    (),
        .M_AWLOCK   (),
        .M_AWSIZE   (),
        .M_AWBURST  (),
        .M_AWCACHE  (),
        .M_AWPROT   (mmio_awprot),
        .M_AWVALID  (mmio_awvalid),
        .M_AWREADY  (mmio_awready),
        .M_AWQOS    (),
        .M_AWREGION (),
        .M_WDATA    (mmio_wdata),
        .M_WSTRB    (mmio_wstrb),
        .M_WLAST    (),
        .M_WVALID   (mmio_wvalid),
        .M_WREADY   (mmio_wready),
        .M_BID      (1'b0),
        .M_BRESP    (mmio_bresp),
        .M_BVALID   (mmio_bvalid),
        .M_BREADY   (mmio_bready),
        .M_ARID     (),
        .M_ARADDR   (mmio_araddr),
        .M_ARLEN    (),
        .M_ARLOCK   (),
        .M_ARSIZE   (),
        .M_ARBURST  (),
        .M_ARCACHE  (),
        .M_ARPROT   (mmio_arprot),
        .M_ARVALID  (mmio_arvalid),
        .M_ARREADY  (mmio_arready),
        .M_ARQOS    (),
        .M_ARREGION (),
        .M_RID      (1'b0),
        .M_RDATA    (mmio_rdata),
        .M_RRESP    (mmio_rresp),
        .M_RLAST    (1'b1),
        .M_RVALID   (mmio_rvalid),
        .M_RREADY   (mmio_rready)
    );

    wire          emu_sys_mem_awready;
    wire          emu_sys_mem_awvalid;
    wire   [31:0] emu_sys_mem_awaddr;
    wire   [2:0]  emu_sys_mem_awprot;
    wire          emu_sys_mem_awid;
    wire          emu_sys_mem_awuser;
    wire   [7:0]  emu_sys_mem_awlen;
    wire   [2:0]  emu_sys_mem_awsize;
    wire   [1:0]  emu_sys_mem_awburst;
    wire          emu_sys_mem_awlock;
    wire   [3:0]  emu_sys_mem_awcache;
    wire   [3:0]  emu_sys_mem_awqos;
    wire          emu_sys_mem_wready;
    wire          emu_sys_mem_wvalid;
    wire   [63:0] emu_sys_mem_wdata;
    wire   [7:0]  emu_sys_mem_wstrb;
    wire          emu_sys_mem_wlast;
    wire          emu_sys_mem_bready;
    wire          emu_sys_mem_bvalid;
    wire   [1:0]  emu_sys_mem_bresp;
    wire          emu_sys_mem_bid;
    wire          emu_sys_mem_buser;
    wire          emu_sys_mem_arready;
    wire          emu_sys_mem_arvalid;
    wire   [31:0] emu_sys_mem_araddr;
    wire   [2:0]  emu_sys_mem_arprot;
    wire          emu_sys_mem_arid;
    wire          emu_sys_mem_aruser;
    wire   [7:0]  emu_sys_mem_arlen;
    wire   [2:0]  emu_sys_mem_arsize;
    wire   [1:0]  emu_sys_mem_arburst;
    wire          emu_sys_mem_arlock;
    wire   [3:0]  emu_sys_mem_arcache;
    wire   [3:0]  emu_sys_mem_arqos;
    wire          emu_sys_mem_rready;
    wire          emu_sys_mem_rvalid;
    wire   [1:0]  emu_sys_mem_rresp;
    wire   [63:0] emu_sys_mem_rdata;
    wire          emu_sys_mem_rlast;
    wire          emu_sys_mem_rid;
    wire          emu_sys_mem_ruser;

    emu_system_wrap sys_inst (
        .host_clk       (clk),
        .host_rst       (rst),
        .mmio_arvalid   (mmio_arvalid),
        .mmio_arready   (mmio_arready),
        .mmio_araddr    (mmio_araddr),
        .mmio_arprot    (mmio_arprot),
        .mmio_rvalid    (mmio_rvalid),
        .mmio_rready    (mmio_rready),
        .mmio_rresp     (mmio_rresp),
        .mmio_rdata     (mmio_rdata),
        .mmio_awvalid   (mmio_awvalid),
        .mmio_awready   (mmio_awready),
        .mmio_awaddr    (mmio_awaddr),
        .mmio_awprot    (mmio_awprot),
        .mmio_wvalid    (mmio_wvalid),
        .mmio_wready    (mmio_wready),
        .mmio_wdata     (mmio_wdata),
        .mmio_wstrb     (mmio_wstrb),
        .mmio_bvalid    (mmio_bvalid),
        .mmio_bready    (mmio_bready),
        .mmio_bresp     (mmio_bresp),
        .mem_awvalid    (emu_sys_mem_awvalid),
        .mem_awready    (emu_sys_mem_awready),
        .mem_awaddr     (emu_sys_mem_awaddr),
        .mem_awid       (emu_sys_mem_awid),
        .mem_awlen      (emu_sys_mem_awlen),
        .mem_awsize     (emu_sys_mem_awsize),
        .mem_awburst    (emu_sys_mem_awburst),
        .mem_awlock     (emu_sys_mem_awlock),
        .mem_awcache    (emu_sys_mem_awcache),
        .mem_awprot     (emu_sys_mem_awprot),
        .mem_awqos      (emu_sys_mem_awqos),
        .mem_wvalid     (emu_sys_mem_wvalid),
        .mem_wready     (emu_sys_mem_wready),
        .mem_wdata      (emu_sys_mem_wdata),
        .mem_wstrb      (emu_sys_mem_wstrb),
        .mem_wlast      (emu_sys_mem_wlast),
        .mem_bvalid     (emu_sys_mem_bvalid),
        .mem_bready     (emu_sys_mem_bready),
        .mem_bresp      (emu_sys_mem_bresp),
        .mem_bid        (emu_sys_mem_bid),
        .mem_arvalid    (emu_sys_mem_arvalid),
        .mem_arready    (emu_sys_mem_arready),
        .mem_araddr     (emu_sys_mem_araddr),
        .mem_arid       (emu_sys_mem_arid),
        .mem_arlen      (emu_sys_mem_arlen),
        .mem_arsize     (emu_sys_mem_arsize),
        .mem_arburst    (emu_sys_mem_arburst),
        .mem_arlock     (emu_sys_mem_arlock),
        .mem_arcache    (emu_sys_mem_arcache),
        .mem_arprot     (emu_sys_mem_arprot),
        .mem_arqos      (emu_sys_mem_arqos),
        .mem_rvalid     (emu_sys_mem_rvalid),
        .mem_rready     (emu_sys_mem_rready),
        .mem_rdata      (emu_sys_mem_rdata),
        .mem_rresp      (emu_sys_mem_rresp),
        .mem_rid        (emu_sys_mem_rid),
        .mem_rlast      (emu_sys_mem_rlast)
    );

    wire          sim_mem_awready;
    wire          sim_mem_awvalid;
    wire   [31:0] sim_mem_awaddr;
    wire   [2:0]  sim_mem_awprot;
    wire          sim_mem_awid;
    wire          sim_mem_awuser;
    wire   [7:0]  sim_mem_awlen;
    wire   [2:0]  sim_mem_awsize;
    wire   [1:0]  sim_mem_awburst;
    wire          sim_mem_awlock;
    wire   [3:0]  sim_mem_awcache;
    wire   [3:0]  sim_mem_awqos;
    wire          sim_mem_wready;
    wire          sim_mem_wvalid;
    wire   [63:0] sim_mem_wdata;
    wire   [7:0]  sim_mem_wstrb;
    wire          sim_mem_wlast;
    wire          sim_mem_bready;
    wire          sim_mem_bvalid;
    wire   [1:0]  sim_mem_bresp;
    wire          sim_mem_bid;
    wire          sim_mem_buser;
    wire          sim_mem_arready;
    wire          sim_mem_arvalid;
    wire   [31:0] sim_mem_araddr;
    wire   [2:0]  sim_mem_arprot;
    wire          sim_mem_arid;
    wire          sim_mem_aruser;
    wire   [7:0]  sim_mem_arlen;
    wire   [2:0]  sim_mem_arsize;
    wire   [1:0]  sim_mem_arburst;
    wire          sim_mem_arlock;
    wire   [3:0]  sim_mem_arcache;
    wire   [3:0]  sim_mem_arqos;
    wire          sim_mem_rready;
    wire          sim_mem_rvalid;
    wire   [1:0]  sim_mem_rresp;
    wire   [63:0] sim_mem_rdata;
    wire          sim_mem_rlast;
    wire          sim_mem_rid;
    wire          sim_mem_ruser;

    axi_interconnect_wrap_2x1 #(
        .DATA_WIDTH     (64),
        .ADDR_WIDTH     (32),
        .ID_WIDTH       (1),
        .M00_BASE_ADDR  ('h00000000),
        .M00_ADDR_WIDTH (32)
    ) mem_xbar (
        .clk            (clk),
        .rst            (rst),

        .s00_axi_awid   (mem_awid),
        .s00_axi_awaddr (mem_awaddr),
        .s00_axi_awlen  (mem_awlen),
        .s00_axi_awsize (mem_awsize),
        .s00_axi_awburst(mem_awburst),
        .s00_axi_awlock (mem_awlock),
        .s00_axi_awcache(mem_awcache),
        .s00_axi_awprot (mem_awprot),
        .s00_axi_awqos  (mem_awqos),
        .s00_axi_awuser (mem_awuser),
        .s00_axi_awvalid(mem_awvalid),
        .s00_axi_awready(mem_awready),
        .s00_axi_wdata  (mem_wdata),
        .s00_axi_wstrb  (mem_wstrb),
        .s00_axi_wlast  (mem_wlast),
        .s00_axi_wuser  (mem_wuser),
        .s00_axi_wvalid (mem_wvalid),
        .s00_axi_wready (mem_wready),
        .s00_axi_bid    (mem_bid),
        .s00_axi_bresp  (mem_bresp),
        .s00_axi_buser  (mem_buser),
        .s00_axi_bvalid (mem_bvalid),
        .s00_axi_bready (mem_bready),
        .s00_axi_arid   (mem_arid),
        .s00_axi_araddr (mem_araddr),
        .s00_axi_arlen  (mem_arlen),
        .s00_axi_arsize (mem_arsize),
        .s00_axi_arburst(mem_arburst),
        .s00_axi_arlock (mem_arlock),
        .s00_axi_arcache(mem_arcache),
        .s00_axi_arprot (mem_arprot),
        .s00_axi_arqos  (mem_arqos),
        .s00_axi_aruser (mem_aruser),
        .s00_axi_arvalid(mem_arvalid),
        .s00_axi_arready(mem_arready),
        .s00_axi_rid    (mem_rid),
        .s00_axi_rdata  (mem_rdata),
        .s00_axi_rresp  (mem_rresp),
        .s00_axi_rlast  (mem_rlast),
        .s00_axi_ruser  (mem_ruser),
        .s00_axi_rvalid (mem_rvalid),
        .s00_axi_rready (mem_rready),

        .s01_axi_awid   (emu_sys_mem_awid),
        .s01_axi_awaddr (emu_sys_mem_awaddr),
        .s01_axi_awlen  (emu_sys_mem_awlen),
        .s01_axi_awsize (emu_sys_mem_awsize),
        .s01_axi_awburst(emu_sys_mem_awburst),
        .s01_axi_awlock (emu_sys_mem_awlock),
        .s01_axi_awcache(emu_sys_mem_awcache),
        .s01_axi_awprot (emu_sys_mem_awprot),
        .s01_axi_awqos  (emu_sys_mem_awqos),
        .s01_axi_awuser (emu_sys_mem_awuser),
        .s01_axi_awvalid(emu_sys_mem_awvalid),
        .s01_axi_awready(emu_sys_mem_awready),
        .s01_axi_wdata  (emu_sys_mem_wdata),
        .s01_axi_wstrb  (emu_sys_mem_wstrb),
        .s01_axi_wlast  (emu_sys_mem_wlast),
        .s01_axi_wuser  (emu_sys_mem_wuser),
        .s01_axi_wvalid (emu_sys_mem_wvalid),
        .s01_axi_wready (emu_sys_mem_wready),
        .s01_axi_bid    (emu_sys_mem_bid),
        .s01_axi_bresp  (emu_sys_mem_bresp),
        .s01_axi_buser  (emu_sys_mem_buser),
        .s01_axi_bvalid (emu_sys_mem_bvalid),
        .s01_axi_bready (emu_sys_mem_bready),
        .s01_axi_arid   (emu_sys_mem_arid),
        .s01_axi_araddr (emu_sys_mem_araddr),
        .s01_axi_arlen  (emu_sys_mem_arlen),
        .s01_axi_arsize (emu_sys_mem_arsize),
        .s01_axi_arburst(emu_sys_mem_arburst),
        .s01_axi_arlock (emu_sys_mem_arlock),
        .s01_axi_arcache(emu_sys_mem_arcache),
        .s01_axi_arprot (emu_sys_mem_arprot),
        .s01_axi_arqos  (emu_sys_mem_arqos),
        .s01_axi_aruser (emu_sys_mem_aruser),
        .s01_axi_arvalid(emu_sys_mem_arvalid),
        .s01_axi_arready(emu_sys_mem_arready),
        .s01_axi_rid    (emu_sys_mem_rid),
        .s01_axi_rdata  (emu_sys_mem_rdata),
        .s01_axi_rresp  (emu_sys_mem_rresp),
        .s01_axi_rlast  (emu_sys_mem_rlast),
        .s01_axi_ruser  (emu_sys_mem_ruser),
        .s01_axi_rvalid (emu_sys_mem_rvalid),
        .s01_axi_rready (emu_sys_mem_rready),

        .m00_axi_awid   (sim_mem_awid),
        .m00_axi_awaddr (sim_mem_awaddr),
        .m00_axi_awlen  (sim_mem_awlen),
        .m00_axi_awsize (sim_mem_awsize),
        .m00_axi_awburst(sim_mem_awburst),
        .m00_axi_awlock (sim_mem_awlock),
        .m00_axi_awcache(sim_mem_awcache),
        .m00_axi_awprot (sim_mem_awprot),
        .m00_axi_awqos  (sim_mem_awqos),
        .m00_axi_awuser (sim_mem_awuser),
        .m00_axi_awvalid(sim_mem_awvalid),
        .m00_axi_awready(sim_mem_awready),
        .m00_axi_wdata  (sim_mem_wdata),
        .m00_axi_wstrb  (sim_mem_wstrb),
        .m00_axi_wlast  (sim_mem_wlast),
        .m00_axi_wuser  (sim_mem_wuser),
        .m00_axi_wvalid (sim_mem_wvalid),
        .m00_axi_wready (sim_mem_wready),
        .m00_axi_bid    (sim_mem_bid),
        .m00_axi_bresp  (sim_mem_bresp),
        .m00_axi_buser  (sim_mem_buser),
        .m00_axi_bvalid (sim_mem_bvalid),
        .m00_axi_bready (sim_mem_bready),
        .m00_axi_arid   (sim_mem_arid),
        .m00_axi_araddr (sim_mem_araddr),
        .m00_axi_arlen  (sim_mem_arlen),
        .m00_axi_arsize (sim_mem_arsize),
        .m00_axi_arburst(sim_mem_arburst),
        .m00_axi_arlock (sim_mem_arlock),
        .m00_axi_arcache(sim_mem_arcache),
        .m00_axi_arprot (sim_mem_arprot),
        .m00_axi_arqos  (sim_mem_arqos),
        .m00_axi_aruser (sim_mem_aruser),
        .m00_axi_arvalid(sim_mem_arvalid),
        .m00_axi_arready(sim_mem_arready),
        .m00_axi_rid    (sim_mem_rid),
        .m00_axi_rdata  (sim_mem_rdata),
        .m00_axi_rresp  (sim_mem_rresp),
        .m00_axi_rlast  (sim_mem_rlast),
        .m00_axi_ruser  (sim_mem_ruser),
        .m00_axi_rvalid (sim_mem_rvalid),
        .m00_axi_rready (sim_mem_rready)
    );

    axi_sim_mem #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (64),
        .ID_WIDTH       (1),
        .MEM_SIZE       ('h20000000),
        .MEM_INIT       (0)
    ) sim_mem_inst (
        .clk            (clk),
        .rst            (rst),
        .s_axi_awid     (sim_mem_awid),
        .s_axi_awaddr   (sim_mem_awaddr),
        .s_axi_awlen    (sim_mem_awlen),
        .s_axi_awsize   (sim_mem_awsize),
        .s_axi_awburst  (sim_mem_awburst),
        .s_axi_awlock   (sim_mem_awlock),
        .s_axi_awcache  (sim_mem_awcache),
        .s_axi_awprot   (sim_mem_awprot),
        .s_axi_awvalid  (sim_mem_awvalid),
        .s_axi_awready  (sim_mem_awready),
        .s_axi_wdata    (sim_mem_wdata),
        .s_axi_wstrb    (sim_mem_wstrb),
        .s_axi_wlast    (sim_mem_wlast),
        .s_axi_wvalid   (sim_mem_wvalid),
        .s_axi_wready   (sim_mem_wready),
        .s_axi_bid      (sim_mem_bid),
        .s_axi_bresp    (sim_mem_bresp),
        .s_axi_bvalid   (sim_mem_bvalid),
        .s_axi_bready   (sim_mem_bready),
        .s_axi_arid     (sim_mem_arid),
        .s_axi_araddr   (sim_mem_araddr),
        .s_axi_arlen    (sim_mem_arlen),
        .s_axi_arsize   (sim_mem_arsize),
        .s_axi_arburst  (sim_mem_arburst),
        .s_axi_arlock   (sim_mem_arlock),
        .s_axi_arcache  (sim_mem_arcache),
        .s_axi_arprot   (sim_mem_arprot),
        .s_axi_arvalid  (sim_mem_arvalid),
        .s_axi_arready  (sim_mem_arready),
        .s_axi_rid      (sim_mem_rid),
        .s_axi_rdata    (sim_mem_rdata),
        .s_axi_rresp    (sim_mem_rresp),
        .s_axi_rlast    (sim_mem_rlast),
        .s_axi_rvalid   (sim_mem_rvalid),
        .s_axi_rready   (sim_mem_rready)
    );

endmodule
