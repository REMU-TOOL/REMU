`timescale 1 ns / 1 ps

module emu_top(
    (* remu_clock *)
    input   clk,
    (* remu_signal *)
    input   rst
);

    (* remu_trigger *)
    wire trap;

	wire          core_axi_awvalid;
	wire          core_axi_awready;
	wire   [31:0] core_axi_awaddr;
	wire   [ 2:0] core_axi_awprot;
	wire          core_axi_wvalid;
	wire          core_axi_wready;
	wire   [31:0] core_axi_wdata;
	wire   [ 3:0] core_axi_wstrb;
	wire          core_axi_bvalid;
	wire          core_axi_bready;
	wire          core_axi_arvalid;
	wire          core_axi_arready;
	wire   [31:0] core_axi_araddr;
	wire   [ 2:0] core_axi_arprot;
	wire          core_axi_rvalid;
	wire          core_axi_rready;
	wire   [31:0] core_axi_rdata;

    picorv32_axi #(
		.COMPRESSED_ISA(1),
		.ENABLE_FAST_MUL(1),
		.ENABLE_DIV(1)
	) dut (
		.clk            (clk            ),
		.resetn         (!rst           ),
		.trap           (trap           ),
        .mem_axi_awvalid(core_axi_awvalid),
        .mem_axi_awready(core_axi_awready),
        .mem_axi_awaddr (core_axi_awaddr),
        .mem_axi_awprot (core_axi_awprot),
        .mem_axi_wvalid (core_axi_wvalid),
        .mem_axi_wready (core_axi_wready),
        .mem_axi_wdata  (core_axi_wdata),
        .mem_axi_wstrb  (core_axi_wstrb),
        .mem_axi_bvalid (core_axi_bvalid),
        .mem_axi_bready (core_axi_bready),
        .mem_axi_arvalid(core_axi_arvalid),
        .mem_axi_arready(core_axi_arready),
        .mem_axi_araddr (core_axi_araddr),
        .mem_axi_arprot (core_axi_arprot),
        .mem_axi_rvalid (core_axi_rvalid),
        .mem_axi_rready (core_axi_rready),
        .mem_axi_rdata  (core_axi_rdata)
	);

    wire [31:0] m00_axil_awaddr;
    wire [2:0]  m00_axil_awprot;
    wire        m00_axil_awvalid;
    wire        m00_axil_awready;
    wire [31:0] m00_axil_wdata;
    wire [3:0]  m00_axil_wstrb;
    wire        m00_axil_wvalid;
    wire        m00_axil_wready;
    wire [1:0]  m00_axil_bresp;
    wire        m00_axil_bvalid;
    wire        m00_axil_bready;
    wire [31:0] m00_axil_araddr;
    wire [2:0]  m00_axil_arprot;
    wire        m00_axil_arvalid;
    wire        m00_axil_arready;
    wire [31:0] m00_axil_rdata;
    wire [1:0]  m00_axil_rresp;
    wire        m00_axil_rvalid;
    wire        m00_axil_rready;

    wire [31:0] m01_axil_awaddr;
    wire [2:0]  m01_axil_awprot;
    wire        m01_axil_awvalid;
    wire        m01_axil_awready;
    wire [31:0] m01_axil_wdata;
    wire [3:0]  m01_axil_wstrb;
    wire        m01_axil_wvalid;
    wire        m01_axil_wready;
    wire [1:0]  m01_axil_bresp;
    wire        m01_axil_bvalid;
    wire        m01_axil_bready;
    wire [31:0] m01_axil_araddr;
    wire [2:0]  m01_axil_arprot;
    wire        m01_axil_arvalid;
    wire        m01_axil_arready;
    wire [31:0] m01_axil_rdata;
    wire [1:0]  m01_axil_rresp;
    wire        m01_axil_rvalid;
    wire        m01_axil_rready;

    axil_interconnect_wrap_1x2 #(
        .DATA_WIDTH     (32),
        .ADDR_WIDTH     (32),
        .M00_BASE_ADDR  (32'h00000000),
        .M00_ADDR_WIDTH (32'd16),
        .M01_BASE_ADDR  (32'h10000000),
        .M01_ADDR_WIDTH (32'd28)
    ) axil_ic (
        .clk                (clk),
        .rst                (rst),
        .s00_axil_awaddr    (core_axi_awaddr),
        .s00_axil_awprot    (core_axi_awprot),
        .s00_axil_awvalid   (core_axi_awvalid),
        .s00_axil_awready   (core_axi_awready),
        .s00_axil_wdata     (core_axi_wdata),
        .s00_axil_wstrb     (core_axi_wstrb),
        .s00_axil_wvalid    (core_axi_wvalid),
        .s00_axil_wready    (core_axi_wready),
        .s00_axil_bresp     (),
        .s00_axil_bvalid    (core_axi_bvalid),
        .s00_axil_bready    (core_axi_bready),
        .s00_axil_araddr    (core_axi_araddr),
        .s00_axil_arprot    (core_axi_arprot),
        .s00_axil_arvalid   (core_axi_arvalid),
        .s00_axil_arready   (core_axi_arready),
        .s00_axil_rdata     (core_axi_rdata),
        .s00_axil_rresp     (),
        .s00_axil_rvalid    (core_axi_rvalid),
        .s00_axil_rready    (core_axi_rready),
        .m00_axil_awaddr    (m00_axil_awaddr),
        .m00_axil_awprot    (m00_axil_awprot),
        .m00_axil_awvalid   (m00_axil_awvalid),
        .m00_axil_awready   (m00_axil_awready),
        .m00_axil_wdata     (m00_axil_wdata),
        .m00_axil_wstrb     (m00_axil_wstrb),
        .m00_axil_wvalid    (m00_axil_wvalid),
        .m00_axil_wready    (m00_axil_wready),
        .m00_axil_bresp     (m00_axil_bresp),
        .m00_axil_bvalid    (m00_axil_bvalid),
        .m00_axil_bready    (m00_axil_bready),
        .m00_axil_araddr    (m00_axil_araddr),
        .m00_axil_arprot    (m00_axil_arprot),
        .m00_axil_arvalid   (m00_axil_arvalid),
        .m00_axil_arready   (m00_axil_arready),
        .m00_axil_rdata     (m00_axil_rdata),
        .m00_axil_rresp     (m00_axil_rresp),
        .m00_axil_rvalid    (m00_axil_rvalid),
        .m00_axil_rready    (m00_axil_rready),
        .m01_axil_awaddr    (m01_axil_awaddr),
        .m01_axil_awprot    (m01_axil_awprot),
        .m01_axil_awvalid   (m01_axil_awvalid),
        .m01_axil_awready   (m01_axil_awready),
        .m01_axil_wdata     (m01_axil_wdata),
        .m01_axil_wstrb     (m01_axil_wstrb),
        .m01_axil_wvalid    (m01_axil_wvalid),
        .m01_axil_wready    (m01_axil_wready),
        .m01_axil_bresp     (m01_axil_bresp),
        .m01_axil_bvalid    (m01_axil_bvalid),
        .m01_axil_bready    (m01_axil_bready),
        .m01_axil_araddr    (m01_axil_araddr),
        .m01_axil_arprot    (m01_axil_arprot),
        .m01_axil_arvalid   (m01_axil_arvalid),
        .m01_axil_arready   (m01_axil_arready),
        .m01_axil_rdata     (m01_axil_rdata),
        .m01_axil_rresp     (m01_axil_rresp),
        .m01_axil_rvalid    (m01_axil_rvalid),
        .m01_axil_rready    (m01_axil_rready)
    );

    EmuRam #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32),
        .ID_WIDTH       (1),
        .MEM_SIZE       (64'h10000),
        .R_DELAY        (0),
        .W_DELAY        (0)
    )
    u_rammodel (
        .clk            (clk),
        .rst            (rst),
        .s_axi_awvalid  (m00_axil_awvalid),
        .s_axi_awready  (m00_axil_awready),
        .s_axi_awaddr   (m00_axil_awaddr),
        .s_axi_awid     (1'b0),
        .s_axi_awlen    (8'd0),
        .s_axi_awsize   (3'd2),
        .s_axi_awburst  (2'd1),
        .s_axi_awlock   (1'd0),
        .s_axi_awcache  (4'd0),
        .s_axi_awprot   (m00_axil_awprot),
        .s_axi_awqos    (4'd0),
        .s_axi_awregion (4'd0),

        .s_axi_wvalid   (m00_axil_wvalid),
        .s_axi_wready   (m00_axil_wready),
        .s_axi_wdata    (m00_axil_wdata),
        .s_axi_wstrb    (m00_axil_wstrb),
        .s_axi_wlast    (1'b1),

        .s_axi_bvalid   (m00_axil_bvalid),
        .s_axi_bready   (m00_axil_bready),
        .s_axi_bresp    (m00_axil_bresp),
        .s_axi_bid      (),

        .s_axi_arvalid  (m00_axil_arvalid),
        .s_axi_arready  (m00_axil_arready),
        .s_axi_araddr   (m00_axil_araddr),
        .s_axi_arid     (1'b0),
        .s_axi_arlen    (8'd0),
        .s_axi_arsize   (3'd2),
        .s_axi_arburst  (2'd1),
        .s_axi_arlock   (1'd0),
        .s_axi_arcache  (4'd0),
        .s_axi_arprot   (m00_axil_arprot),
        .s_axi_arqos    (4'd0),
        .s_axi_arregion (4'd0),

        .s_axi_rvalid   (m00_axil_rvalid),
        .s_axi_rready   (m00_axil_rready),
        .s_axi_rdata    (m00_axil_rdata),
        .s_axi_rresp    (m00_axil_rresp),
        .s_axi_rid      (),
        .s_axi_rlast    ()
    );

    EmuUart u_uart (
        .clk                (clk),
        .rst                (rst),
        .s_axilite_awaddr   (m01_axil_awaddr),
        .s_axilite_awprot   (m01_axil_awprot),
        .s_axilite_awvalid  (m01_axil_awvalid),
        .s_axilite_awready  (m01_axil_awready),
        .s_axilite_wdata    (m01_axil_wdata),
        .s_axilite_wstrb    (m01_axil_wstrb),
        .s_axilite_wvalid   (m01_axil_wvalid),
        .s_axilite_wready   (m01_axil_wready),
        .s_axilite_bresp    (m01_axil_bresp),
        .s_axilite_bvalid   (m01_axil_bvalid),
        .s_axilite_bready   (m01_axil_bready),
        .s_axilite_araddr   (m01_axil_araddr),
        .s_axilite_arprot   (m01_axil_arprot),
        .s_axilite_arvalid  (m01_axil_arvalid),
        .s_axilite_arready  (m01_axil_arready),
        .s_axilite_rdata    (m01_axil_rdata),
        .s_axilite_rresp    (m01_axil_rresp),
        .s_axilite_rvalid   (m01_axil_rvalid),
        .s_axilite_rready   (m01_axil_rready)
    );

endmodule
