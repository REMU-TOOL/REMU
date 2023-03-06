`timescale 1 ns / 1 ps

module emu_top(
    (* remu_clock *)
    input   clk,
    (* remu_signal *)
    input   rst
);

    wire          io_mem_awready;
    wire          io_mem_awvalid;
    wire   [31:0] io_mem_awaddr;
    wire   [2:0]  io_mem_awprot;
    wire          io_mem_awid;
    wire          io_mem_awuser;
    wire   [7:0]  io_mem_awlen;
    wire   [2:0]  io_mem_awsize;
    wire   [1:0]  io_mem_awburst;
    wire          io_mem_awlock;
    wire   [3:0]  io_mem_awcache;
    wire   [3:0]  io_mem_awqos;
    wire          io_mem_wready;
    wire          io_mem_wvalid;
    wire   [63:0] io_mem_wdata;
    wire   [7:0]  io_mem_wstrb;
    wire          io_mem_wlast;
    wire          io_mem_bready;
    wire          io_mem_bvalid;
    wire   [1:0]  io_mem_bresp;
    wire          io_mem_bid;
    wire          io_mem_buser;
    wire          io_mem_arready;
    wire          io_mem_arvalid;
    wire   [31:0] io_mem_araddr;
    wire   [2:0]  io_mem_arprot;
    wire          io_mem_arid;
    wire          io_mem_aruser;
    wire   [7:0]  io_mem_arlen;
    wire   [2:0]  io_mem_arsize;
    wire   [1:0]  io_mem_arburst;
    wire          io_mem_arlock;
    wire   [3:0]  io_mem_arcache;
    wire   [3:0]  io_mem_arqos;
    wire          io_mem_rready;
    wire          io_mem_rvalid;
    wire   [1:0]  io_mem_rresp;
    wire   [63:0] io_mem_rdata;
    wire          io_mem_rlast;
    wire          io_mem_rid;
    wire          io_mem_ruser;
    wire          io_mmio_awready;
    wire          io_mmio_awvalid;
    wire   [31:0] io_mmio_awaddr;
    wire   [2:0]  io_mmio_awprot;
    wire          io_mmio_awid;
    wire          io_mmio_awuser;
    wire   [7:0]  io_mmio_awlen;
    wire   [2:0]  io_mmio_awsize;
    wire   [1:0]  io_mmio_awburst;
    wire          io_mmio_awlock;
    wire   [3:0]  io_mmio_awcache;
    wire   [3:0]  io_mmio_awqos;
    wire          io_mmio_wready;
    wire          io_mmio_wvalid;
    wire   [63:0] io_mmio_wdata;
    wire   [7:0]  io_mmio_wstrb;
    wire          io_mmio_wlast;
    wire          io_mmio_bready;
    wire          io_mmio_bvalid;
    wire   [1:0]  io_mmio_bresp;
    wire          io_mmio_bid;
    wire          io_mmio_buser;
    wire          io_mmio_arready;
    wire          io_mmio_arvalid;
    wire   [31:0] io_mmio_araddr;
    wire   [2:0]  io_mmio_arprot;
    wire          io_mmio_arid;
    wire          io_mmio_aruser;
    wire   [7:0]  io_mmio_arlen;
    wire   [2:0]  io_mmio_arsize;
    wire   [1:0]  io_mmio_arburst;
    wire          io_mmio_arlock;
    wire   [3:0]  io_mmio_arcache;
    wire   [3:0]  io_mmio_arqos;
    wire          io_mmio_rready;
    wire          io_mmio_rvalid;
    wire   [1:0]  io_mmio_rresp;
    wire   [63:0] io_mmio_rdata;
    wire          io_mmio_rlast;
    wire          io_mmio_rid;
    wire          io_mmio_ruser;

    NutShell nutshell(
        .clock                  (clk),
        .reset                  (rst),
        .io_mem_awready         (io_mem_awready),
        .io_mem_awvalid         (io_mem_awvalid),
        .io_mem_awaddr          (io_mem_awaddr),
        .io_mem_awprot          (io_mem_awprot),
        .io_mem_awid            (io_mem_awid),
        .io_mem_awuser          (io_mem_awuser),
        .io_mem_awlen           (io_mem_awlen),
        .io_mem_awsize          (io_mem_awsize),
        .io_mem_awburst         (io_mem_awburst),
        .io_mem_awlock          (io_mem_awlock),
        .io_mem_awcache         (io_mem_awcache),
        .io_mem_awqos           (io_mem_awqos),
        .io_mem_wready          (io_mem_wready),
        .io_mem_wvalid          (io_mem_wvalid),
        .io_mem_wdata           (io_mem_wdata),
        .io_mem_wstrb           (io_mem_wstrb),
        .io_mem_wlast           (io_mem_wlast),
        .io_mem_bready          (io_mem_bready),
        .io_mem_bvalid          (io_mem_bvalid),
        .io_mem_bresp           (io_mem_bresp),
        .io_mem_bid             (io_mem_bid),
        .io_mem_buser           (io_mem_buser),
        .io_mem_arready         (io_mem_arready),
        .io_mem_arvalid         (io_mem_arvalid),
        .io_mem_araddr          (io_mem_araddr),
        .io_mem_arprot          (io_mem_arprot),
        .io_mem_arid            (io_mem_arid),
        .io_mem_aruser          (io_mem_aruser),
        .io_mem_arlen           (io_mem_arlen),
        .io_mem_arsize          (io_mem_arsize),
        .io_mem_arburst         (io_mem_arburst),
        .io_mem_arlock          (io_mem_arlock),
        .io_mem_arcache         (io_mem_arcache),
        .io_mem_arqos           (io_mem_arqos),
        .io_mem_rready          (io_mem_rready),
        .io_mem_rvalid          (io_mem_rvalid),
        .io_mem_rresp           (io_mem_rresp),
        .io_mem_rdata           (io_mem_rdata),
        .io_mem_rlast           (io_mem_rlast),
        .io_mem_rid             (io_mem_rid),
        .io_mem_ruser           (io_mem_ruser),
        .io_mmio_awready        (io_mmio_awready),
        .io_mmio_awvalid        (io_mmio_awvalid),
        .io_mmio_awaddr         (io_mmio_awaddr),
        .io_mmio_awprot         (io_mmio_awprot),
        .io_mmio_awid           (io_mmio_awid),
        .io_mmio_awuser         (io_mmio_awuser),
        .io_mmio_awlen          (io_mmio_awlen),
        .io_mmio_awsize         (io_mmio_awsize),
        .io_mmio_awburst        (io_mmio_awburst),
        .io_mmio_awlock         (io_mmio_awlock),
        .io_mmio_awcache        (io_mmio_awcache),
        .io_mmio_awqos          (io_mmio_awqos),
        .io_mmio_wready         (io_mmio_wready),
        .io_mmio_wvalid         (io_mmio_wvalid),
        .io_mmio_wdata          (io_mmio_wdata),
        .io_mmio_wstrb          (io_mmio_wstrb),
        .io_mmio_wlast          (io_mmio_wlast),
        .io_mmio_bready         (io_mmio_bready),
        .io_mmio_bvalid         (io_mmio_bvalid),
        .io_mmio_bresp          (io_mmio_bresp),
        .io_mmio_bid            (io_mmio_bid),
        .io_mmio_buser          (io_mmio_buser),
        .io_mmio_arready        (io_mmio_arready),
        .io_mmio_arvalid        (io_mmio_arvalid),
        .io_mmio_araddr         (io_mmio_araddr),
        .io_mmio_arprot         (io_mmio_arprot),
        .io_mmio_arid           (io_mmio_arid),
        .io_mmio_aruser         (io_mmio_aruser),
        .io_mmio_arlen          (io_mmio_arlen),
        .io_mmio_arsize         (io_mmio_arsize),
        .io_mmio_arburst        (io_mmio_arburst),
        .io_mmio_arlock         (io_mmio_arlock),
        .io_mmio_arcache        (io_mmio_arcache),
        .io_mmio_arqos          (io_mmio_arqos),
        .io_mmio_rready         (io_mmio_rready),
        .io_mmio_rvalid         (io_mmio_rvalid),
        .io_mmio_rresp          (io_mmio_rresp),
        .io_mmio_rdata          (io_mmio_rdata),
        .io_mmio_rlast          (io_mmio_rlast),
        .io_mmio_rid            (io_mmio_rid),
        .io_mmio_ruser          (io_mmio_ruser),
        .io_frontend_awready    (),
        .io_frontend_awvalid    (1'b0),
        .io_frontend_awaddr     (),
        .io_frontend_awprot     (),
        .io_frontend_awid       (),
        .io_frontend_awuser     (),
        .io_frontend_awlen      (),
        .io_frontend_awsize     (),
        .io_frontend_awburst    (),
        .io_frontend_awlock     (),
        .io_frontend_awcache    (),
        .io_frontend_awqos      (),
        .io_frontend_wready     (),
        .io_frontend_wvalid     (1'b0),
        .io_frontend_wdata      (),
        .io_frontend_wstrb      (),
        .io_frontend_wlast      (),
        .io_frontend_bready     (1'b0),
        .io_frontend_bvalid     (),
        .io_frontend_bresp      (),
        .io_frontend_bid        (),
        .io_frontend_buser      (),
        .io_frontend_arready    (),
        .io_frontend_arvalid    (1'b0),
        .io_frontend_araddr     (),
        .io_frontend_arprot     (),
        .io_frontend_arid       (),
        .io_frontend_aruser     (),
        .io_frontend_arlen      (),
        .io_frontend_arsize     (),
        .io_frontend_arburst    (),
        .io_frontend_arlock     (),
        .io_frontend_arcache    (),
        .io_frontend_arqos      (),
        .io_frontend_rready     (1'b0),
        .io_frontend_rvalid     (),
        .io_frontend_rresp      (),
        .io_frontend_rdata      (),
        .io_frontend_rlast      (),
        .io_frontend_rid        (),
        .io_frontend_ruser      (),
        .io_meip                (3'd0),
        .io_ila_WBUpc           (),
        .io_ila_WBUvalid        (),
        .io_ila_WBUrfWen        (),
        .io_ila_WBUrfDest       (),
        .io_ila_WBUrfData       (),
        .io_ila_InstrCnt        ()
    );

    wire [31:0] mmio_axil_awaddr;
    wire [2:0]  mmio_axil_awprot;
    wire        mmio_axil_awvalid;
    wire        mmio_axil_awready;
    wire [31:0] mmio_axil_wdata;
    wire [3:0]  mmio_axil_wstrb;
    wire        mmio_axil_wvalid;
    wire        mmio_axil_wready;
    wire [1:0]  mmio_axil_bresp;
    wire        mmio_axil_bvalid;
    wire        mmio_axil_bready;
    wire [31:0] mmio_axil_araddr;
    wire [2:0]  mmio_axil_arprot;
    wire        mmio_axil_arvalid;
    wire        mmio_axil_arready;
    wire [31:0] mmio_axil_rdata;
    wire [1:0]  mmio_axil_rresp;
    wire        mmio_axil_rvalid;
    wire        mmio_axil_rready;

    axi_axil_adapter #(
        .ADDR_WIDTH         (32),
        .AXI_DATA_WIDTH     (64),
        .AXI_ID_WIDTH       (1),
        .AXIL_DATA_WIDTH    (32)
    ) mmio_axi_to_axil (
        .clk                (clk),
        .rst                (rst),
        .s_axi_awid         (io_mmio_awid),
        .s_axi_awaddr       (io_mmio_awaddr),
        .s_axi_awlen        (io_mmio_awlen),
        .s_axi_awsize       (io_mmio_awsize),
        .s_axi_awburst      (io_mmio_awburst),
        .s_axi_awlock       (io_mmio_awlock),
        .s_axi_awcache      (io_mmio_awcache),
        .s_axi_awregion     (4'd0),
        .s_axi_awqos        (io_mmio_awqos),
        .s_axi_awprot       (io_mmio_awprot),
        .s_axi_awvalid      (io_mmio_awvalid),
        .s_axi_awready      (io_mmio_awready),
        .s_axi_wdata        (io_mmio_wdata),
        .s_axi_wstrb        (io_mmio_wstrb),
        .s_axi_wlast        (io_mmio_wlast),
        .s_axi_wvalid       (io_mmio_wvalid),
        .s_axi_wready       (io_mmio_wready),
        .s_axi_bid          (io_mmio_bid),
        .s_axi_bresp        (io_mmio_bresp),
        .s_axi_bvalid       (io_mmio_bvalid),
        .s_axi_bready       (io_mmio_bready),
        .s_axi_arid         (io_mmio_arid),
        .s_axi_araddr       (io_mmio_araddr),
        .s_axi_arlen        (io_mmio_arlen),
        .s_axi_arsize       (io_mmio_arsize),
        .s_axi_arburst      (io_mmio_arburst),
        .s_axi_arlock       (io_mmio_arlock),
        .s_axi_arcache      (io_mmio_arcache),
        .s_axi_arregion     (4'd0),
        .s_axi_arqos        (io_mmio_arqos),
        .s_axi_arprot       (io_mmio_arprot),
        .s_axi_arvalid      (io_mmio_arvalid),
        .s_axi_arready      (io_mmio_arready),
        .s_axi_rid          (io_mmio_rid),
        .s_axi_rdata        (io_mmio_rdata),
        .s_axi_rresp        (io_mmio_rresp),
        .s_axi_rlast        (io_mmio_rlast),
        .s_axi_rvalid       (io_mmio_rvalid),
        .s_axi_rready       (io_mmio_rready),
        .m_axil_awaddr      (mmio_axil_awaddr),
        .m_axil_awprot      (mmio_axil_awprot),
        .m_axil_awvalid     (mmio_axil_awvalid),
        .m_axil_awready     (mmio_axil_awready),
        .m_axil_wdata       (mmio_axil_wdata),
        .m_axil_wstrb       (mmio_axil_wstrb),
        .m_axil_wvalid      (mmio_axil_wvalid),
        .m_axil_wready      (mmio_axil_wready),
        .m_axil_bresp       (mmio_axil_bresp),
        .m_axil_bvalid      (mmio_axil_bvalid),
        .m_axil_bready      (mmio_axil_bready),
        .m_axil_araddr      (mmio_axil_araddr),
        .m_axil_arprot      (mmio_axil_arprot),
        .m_axil_arvalid     (mmio_axil_arvalid),
        .m_axil_arready     (mmio_axil_arready),
        .m_axil_rdata       (mmio_axil_rdata),
        .m_axil_rresp       (mmio_axil_rresp),
        .m_axil_rvalid      (mmio_axil_rvalid),
        .m_axil_rready      (mmio_axil_rready)
    );

    EmuRam #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (64),
        .ID_WIDTH       (1),
        .MEM_SIZE       (64'h10000000),
        .R_DELAY        (50),
        .W_DELAY        (50)
    )
    u_rammodel (
        .clk            (clk),
        .rst            (rst),
        .s_axi_awready  (io_mem_awready),
        .s_axi_awvalid  (io_mem_awvalid),
        .s_axi_awaddr   ({4'd0, io_mem_awaddr[27:0]}),
        .s_axi_awprot   (io_mem_awprot),
        .s_axi_awid     (io_mem_awid),
        .s_axi_awlen    (io_mem_awlen),
        .s_axi_awsize   (io_mem_awsize),
        .s_axi_awburst  (io_mem_awburst),
        .s_axi_awlock   (io_mem_awlock),
        .s_axi_awcache  (io_mem_awcache),
        .s_axi_awqos    (io_mem_awqos),
        .s_axi_wready   (io_mem_wready),
        .s_axi_wvalid   (io_mem_wvalid),
        .s_axi_wdata    (io_mem_wdata),
        .s_axi_wstrb    (io_mem_wstrb),
        .s_axi_wlast    (io_mem_wlast),
        .s_axi_bready   (io_mem_bready),
        .s_axi_bvalid   (io_mem_bvalid),
        .s_axi_bresp    (io_mem_bresp),
        .s_axi_bid      (io_mem_bid),
        .s_axi_arready  (io_mem_arready),
        .s_axi_arvalid  (io_mem_arvalid),
        .s_axi_araddr   ({4'd0, io_mem_araddr[27:0]}),
        .s_axi_arprot   (io_mem_arprot),
        .s_axi_arid     (io_mem_arid),
        .s_axi_arlen    (io_mem_arlen),
        .s_axi_arsize   (io_mem_arsize),
        .s_axi_arburst  (io_mem_arburst),
        .s_axi_arlock   (io_mem_arlock),
        .s_axi_arcache  (io_mem_arcache),
        .s_axi_arqos    (io_mem_arqos),
        .s_axi_rready   (io_mem_rready),
        .s_axi_rvalid   (io_mem_rvalid),
        .s_axi_rresp    (io_mem_rresp),
        .s_axi_rdata    (io_mem_rdata),
        .s_axi_rlast    (io_mem_rlast),
        .s_axi_rid      (io_mem_rid)
    );

    EmuUart u_uart (
        .clk                (clk),
        .rst                (rst),
        .s_axilite_awaddr   (mmio_axil_awaddr),
        .s_axilite_awprot   (mmio_axil_awprot),
        .s_axilite_awvalid  (mmio_axil_awvalid),
        .s_axilite_awready  (mmio_axil_awready),
        .s_axilite_wdata    (mmio_axil_wdata),
        .s_axilite_wstrb    (mmio_axil_wstrb),
        .s_axilite_wvalid   (mmio_axil_wvalid),
        .s_axilite_wready   (mmio_axil_wready),
        .s_axilite_bresp    (mmio_axil_bresp),
        .s_axilite_bvalid   (mmio_axil_bvalid),
        .s_axilite_bready   (mmio_axil_bready),
        .s_axilite_araddr   (mmio_axil_araddr),
        .s_axilite_arprot   (mmio_axil_arprot),
        .s_axilite_arvalid  (mmio_axil_arvalid),
        .s_axilite_arready  (mmio_axil_arready),
        .s_axilite_rdata    (mmio_axil_rdata),
        .s_axilite_rresp    (mmio_axil_rresp),
        .s_axilite_rvalid   (mmio_axil_rvalid),
        .s_axilite_rready   (mmio_axil_rready)
    );

endmodule
