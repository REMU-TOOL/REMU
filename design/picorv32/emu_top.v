`timescale 1 ns / 1 ps

module emu_top();

    wire clk;
    EmuClock clock(
        .clock(clk)
    );

    wire rst;
    EmuReset reset(
        .reset(rst)
    );

    wire trap;
    EmuTrigger trap_trig(
        .trigger(trap)
    );

	wire          mem_axi_awvalid;
	wire          mem_axi_awready;
	wire   [31:0] mem_axi_awaddr;
	wire   [ 2:0] mem_axi_awprot;

	wire          mem_axi_wvalid;
	wire          mem_axi_wready;
	wire   [31:0] mem_axi_wdata;
	wire   [ 3:0] mem_axi_wstrb;

	wire          mem_axi_bvalid;
	wire          mem_axi_bready;

	wire          mem_axi_arvalid;
	wire          mem_axi_arready;
	wire   [31:0] mem_axi_araddr;
	wire   [ 2:0] mem_axi_arprot;

	wire          mem_axi_rvalid;
	wire          mem_axi_rready;
	wire   [31:0] mem_axi_rdata;

    picorv32_axi #(
		.COMPRESSED_ISA(1),
		.ENABLE_FAST_MUL(1),
		.ENABLE_DIV(1)
	) dut (
		.clk            (clk            ),
		.resetn         (!rst           ),
		.trap           (trap           ),
		.mem_axi_awvalid(mem_axi_awvalid),
		.mem_axi_awready(mem_axi_awready),
		.mem_axi_awaddr (mem_axi_awaddr ),
		.mem_axi_awprot (mem_axi_awprot ),
		.mem_axi_wvalid (mem_axi_wvalid ),
		.mem_axi_wready (mem_axi_wready ),
		.mem_axi_wdata  (mem_axi_wdata  ),
		.mem_axi_wstrb  (mem_axi_wstrb  ),
		.mem_axi_bvalid (mem_axi_bvalid ),
		.mem_axi_bready (mem_axi_bready ),
		.mem_axi_arvalid(mem_axi_arvalid),
		.mem_axi_arready(mem_axi_arready),
		.mem_axi_araddr (mem_axi_araddr ),
		.mem_axi_arprot (mem_axi_arprot ),
		.mem_axi_rvalid (mem_axi_rvalid ),
		.mem_axi_rready (mem_axi_rready ),
		.mem_axi_rdata  (mem_axi_rdata  )
	);

    rammodel #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32),
        .ID_WIDTH       (1),
        .R_DELAY        (0),
        .W_DELAY        (0)
    )
    u_rammodel (
        .aclk           (clk),
        .aresetn        (!rst),
        .s_axi_awvalid  (mem_axi_awvalid),
        .s_axi_awready  (mem_axi_awready),
        .s_axi_awaddr   (mem_axi_awaddr),
        .s_axi_awid     (1'b0),
        .s_axi_awlen    (8'd0),
        .s_axi_awsize   (3'd2),
        .s_axi_awburst  (2'd1),
        .s_axi_awlock   (1'd0),
        .s_axi_awcache  (4'd0),
        .s_axi_awprot   (mem_axi_awprot),
        .s_axi_awqos    (4'd0),
        .s_axi_awregion (4'd0),

        .s_axi_wvalid   (mem_axi_wvalid),
        .s_axi_wready   (mem_axi_wready),
        .s_axi_wdata    (mem_axi_wdata),
        .s_axi_wstrb    (mem_axi_wstrb),
        .s_axi_wlast    (1'b1),

        .s_axi_bvalid   (mem_axi_bvalid),
        .s_axi_bready   (mem_axi_bready),
        .s_axi_bresp    (),
        .s_axi_bid      (),

        .s_axi_arvalid  (mem_axi_arvalid),
        .s_axi_arready  (mem_axi_arready),
        .s_axi_araddr   (mem_axi_araddr),
        .s_axi_arid     (1'b0),
        .s_axi_arlen    (8'd0),
        .s_axi_arsize   (3'd2),
        .s_axi_arburst  (2'd1),
        .s_axi_arlock   (1'd0),
        .s_axi_arcache  (4'd0),
        .s_axi_arprot   (mem_axi_arprot),
        .s_axi_arqos    (4'd0),
        .s_axi_arregion (4'd0),

        .s_axi_rvalid   (mem_axi_rvalid),
        .s_axi_rready   (mem_axi_rready),
        .s_axi_rdata    (mem_axi_rdata),
        .s_axi_rresp    (),
        .s_axi_rid      (),
        .s_axi_rlast    ()
    );

endmodule
