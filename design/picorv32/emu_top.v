`timescale 1 ns / 1 ps
`default_nettype none

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

	wire        mem_valid;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [ 3:0] mem_wstrb;
	wire        mem_instr;
	wire        mem_ready;
	wire [31:0] mem_rdata;

    picorv32 #(
		.COMPRESSED_ISA(1),
		.ENABLE_FAST_MUL(1),
		.ENABLE_DIV(1)
	) dut (
		.clk            (clk            ),
		.resetn         (!rst           ),
		.trap           (trap           ),

		.mem_valid(mem_valid),
		.mem_addr (mem_addr ),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_instr(mem_instr),
		.mem_ready(mem_ready),
		.mem_rdata(mem_rdata)
	);

    emu_uncore uncore (
		.clk            (clk            ),
		.resetn         (!rst           ),
		.mem_valid      (mem_valid      ),
		.mem_instr      (mem_instr      ),
		.mem_ready      (mem_ready      ),
		.mem_addr       (mem_addr       ),
		.mem_wdata      (mem_wdata      ),
		.mem_wstrb      (mem_wstrb      ),
		.mem_rdata      (mem_rdata      )
    );

endmodule

module emu_uncore (
	input clk, resetn,

	// Native PicoRV32 memory interface

	input               mem_valid,
	input               mem_instr,
	output              mem_ready,
	input       [31:0]  mem_addr,
	input       [31:0]  mem_wdata,
	input       [ 3:0]  mem_wstrb,
	output      [31:0]  mem_rdata
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

	wire aw_fire    = mem_axi_awvalid && mem_axi_awready;
	wire w_fire     = mem_axi_wvalid && mem_axi_wready;
	wire b_fire     = mem_axi_bvalid && mem_axi_bready;
	wire ar_fire    = mem_axi_arvalid && mem_axi_arready;
	wire r_fire     = mem_axi_rvalid && mem_axi_rready;

    reg uart_ack;

    always @(posedge clk)
        if (!resetn)
            uart_ack <= 1'b0;
        else if (mem_valid && mem_ready)
            uart_ack <= 1'b0;
        else if (mem_valid && |mem_wstrb && mem_addr == 32'h10000000)
            uart_ack <= 1'b1;

    EmuPutChar u_putchar (
        .clk    (clk),
        .rst    (!resetn),
        .valid  (uart_ack),
        .data   (mem_wdata[7:0] & {8{mem_wstrb[0]}})
    );

    reg aw_done, w_done, ar_done;

    always @(posedge clk)
        if (!resetn)
            aw_done <= 1'b0;
        else if (b_fire)
            aw_done <= 1'b0;
        else if (aw_fire)
            aw_done <= 1'b1;

    always @(posedge clk)
        if (!resetn)
            w_done <= 1'b0;
        else if (b_fire)
            w_done <= 1'b0;
        else if (w_fire)
            w_done <= 1'b1;

    always @(posedge clk)
        if (!resetn)
            ar_done <= 1'b0;
        else if (r_fire)
            ar_done <= 1'b0;
        else if (ar_fire)
            ar_done <= 1'b1;

    assign mem_axi_awvalid  = mem_valid && |mem_wstrb && ~|mem_addr[31:28] && !aw_done;
    assign mem_axi_awaddr   = mem_addr;
    assign mem_axi_awprot   = 3'd0;

    assign mem_axi_wvalid   = mem_valid && |mem_wstrb && ~|mem_addr[31:28] && !w_done;
    assign mem_axi_wdata    = mem_wdata;
    assign mem_axi_wstrb    = mem_wstrb;

    assign mem_axi_bready   = aw_done && w_done;

    assign mem_axi_arvalid  = mem_valid && ~|mem_wstrb && ~|mem_addr[31:28] && !ar_done;
    assign mem_axi_araddr   = mem_addr;
    assign mem_axi_arprot   = 3'd0;

    assign mem_axi_rready   = ar_done;

    assign mem_ready        = b_fire || r_fire || uart_ack;
    assign mem_rdata        = mem_axi_rdata;

    EmuRam #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32),
        .ID_WIDTH       (1),
        .R_DELAY        (0),
        .W_DELAY        (0)
    )
    u_rammodel (
        .clk            (clk),
        .rst            (!resetn),
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

`default_nettype wire
