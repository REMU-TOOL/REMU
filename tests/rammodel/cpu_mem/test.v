`timescale 1ns / 1ps

module test(

    input                       clk,
    input                       resetn,

    output                      trig,

    output reg                  pause,
    input                       do_pause,
    input                       do_resume,

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
    output                      dut_clk,

    output reg  [63:0]          count,
    input                       count_write,
    input   [63:0]              count_wdata,

    input                       step_write,
    input   [63:0]              step_wdata,
    output                      step_trig

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

    wire              mem_axi_awvalid;
	wire              mem_axi_awready;
	wire       [31:0] mem_axi_awaddr;

	wire              mem_axi_wvalid;
	wire              mem_axi_wready;
	wire       [31:0] mem_axi_wdata;
	wire       [ 3:0] mem_axi_wstrb;

	wire              mem_axi_bvalid;
	wire              mem_axi_bready;

	wire              mem_axi_arvalid;
	wire              mem_axi_arready;
	wire       [31:0] mem_axi_araddr;

	wire              mem_axi_rvalid;
	wire              mem_axi_rready;
	wire       [31:0] mem_axi_rdata;

    EMU_DUT emu_dut(
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
        .EMU_DUT_TRIG       (trig),
        .EMU_INTERNAL_CLOCK             (clk),
        .EMU_INTERNAL_RESET             (rst),
        .EMU_INTERNAL_PAUSE             (pause),
        .EMU_INTERNAL_UP_REQ            (up_req),
        .EMU_INTERNAL_DOWN_REQ          (down_req),
        .EMU_INTERNAL_UP_STAT           (up),
        .EMU_INTERNAL_DOWN_STAT         (down),
        .EMU_INTERNAL_STALL             (dut_stall),
        .EMU_INTERNAL_AUTO_0_DRAM_AWVALID       (mem_axi_awvalid),
        .EMU_INTERNAL_AUTO_0_DRAM_AWREADY       (mem_axi_awready),
        .EMU_INTERNAL_AUTO_0_DRAM_AWADDR        (mem_axi_awaddr),
        .EMU_INTERNAL_AUTO_0_DRAM_AWID          (),
        .EMU_INTERNAL_AUTO_0_DRAM_AWLEN         (),
        .EMU_INTERNAL_AUTO_0_DRAM_AWSIZE        (),
        .EMU_INTERNAL_AUTO_0_DRAM_AWBURST       (),
        .EMU_INTERNAL_AUTO_0_DRAM_WVALID        (mem_axi_wvalid),
        .EMU_INTERNAL_AUTO_0_DRAM_WREADY        (mem_axi_wready),
        .EMU_INTERNAL_AUTO_0_DRAM_WDATA         (mem_axi_wdata),
        .EMU_INTERNAL_AUTO_0_DRAM_WSTRB         (mem_axi_wstrb),
        .EMU_INTERNAL_AUTO_0_DRAM_WLAST         (),
        .EMU_INTERNAL_AUTO_0_DRAM_BVALID        (mem_axi_bvalid),
        .EMU_INTERNAL_AUTO_0_DRAM_BREADY        (mem_axi_bready),
        .EMU_INTERNAL_AUTO_0_DRAM_BID           (1'd0),
        .EMU_INTERNAL_AUTO_0_DRAM_ARVALID       (mem_axi_arvalid),
        .EMU_INTERNAL_AUTO_0_DRAM_ARREADY       (mem_axi_arready),
        .EMU_INTERNAL_AUTO_0_DRAM_ARADDR        (mem_axi_araddr),
        .EMU_INTERNAL_AUTO_0_DRAM_ARID          (),
        .EMU_INTERNAL_AUTO_0_DRAM_ARLEN         (),
        .EMU_INTERNAL_AUTO_0_DRAM_ARSIZE        (),
        .EMU_INTERNAL_AUTO_0_DRAM_ARBURST       (),
        .EMU_INTERNAL_AUTO_0_DRAM_RVALID        (mem_axi_rvalid),
        .EMU_INTERNAL_AUTO_0_DRAM_RREADY        (mem_axi_rready),
        .EMU_INTERNAL_AUTO_0_DRAM_RDATA         (mem_axi_rdata),
        .EMU_INTERNAL_AUTO_0_DRAM_RID           (1'd0),
        .EMU_INTERNAL_AUTO_0_DRAM_RLAST         (1'b1)
    );

    reg [7:0] mem [0:64*1024-1];

    reg [31:0] reg_write_addr;
    reg [31:0] reg_write_data;
    reg [3:0] reg_write_strb;
    reg reg_write_addr_valid, reg_write_data_valid, reg_write_resp_valid;
    wire reg_write_addr_data_ok = reg_write_addr_valid && reg_write_data_valid;

    always @(posedge clk) begin
        if (rst) begin
            reg_write_addr          <= 12'd0;
            reg_write_data          <= 32'd0;
            reg_write_strb          <= 4'd0;
            reg_write_addr_valid    <= 1'b0;
            reg_write_data_valid    <= 1'b0;
            reg_write_resp_valid    <= 1'b0;
        end
        else begin
            if (mem_axi_awvalid && mem_axi_awready) begin
                reg_write_addr          <= mem_axi_awaddr;
                reg_write_addr_valid    <= 1'b1;
            end
            if (mem_axi_wvalid && mem_axi_wready) begin
                reg_write_data          <= mem_axi_wdata;
                reg_write_strb          <= mem_axi_wstrb;
                reg_write_data_valid    <= 1'b1;
            end
            if (reg_write_addr_data_ok) begin
                reg_write_addr_valid    <= 1'b0;
                reg_write_data_valid    <= 1'b0;
                reg_write_resp_valid    <= 1'b1;
            end
            if (mem_axi_bvalid && mem_axi_bready) begin
                reg_write_resp_valid    <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if (reg_write_addr_data_ok) begin
            if (reg_write_addr == 32'h1000_0000) begin
                $write("%c", reg_write_data[7:0]);
				$fflush();
            end
            else begin
                if (reg_write_strb[0]) mem[reg_write_addr + 0] <= reg_write_data[ 7: 0];
                if (reg_write_strb[1]) mem[reg_write_addr + 1] <= reg_write_data[15: 8];
                if (reg_write_strb[2]) mem[reg_write_addr + 2] <= reg_write_data[23:16];
                if (reg_write_strb[3]) mem[reg_write_addr + 3] <= reg_write_data[31:24];
            end
        end
    end

    assign mem_axi_awready    = !reg_write_addr_valid && !reg_write_resp_valid;
    assign mem_axi_wready     = !reg_write_data_valid;
    assign mem_axi_bvalid     = reg_write_resp_valid;

    reg [31:0] reg_read_addr;
    reg [31:0] reg_read_data;
    reg reg_read_addr_valid, reg_read_data_valid;
    wire reg_do_read = reg_read_addr_valid && !reg_read_data_valid;

    always @(posedge clk) begin
        if (rst) begin
            reg_read_addr       <= 12'd0;
            reg_read_data       <= 32'd0;
            reg_read_addr_valid <= 1'b0;
            reg_read_data_valid <= 1'b0;
        end
        else begin
            if (mem_axi_arvalid && mem_axi_arready) begin
                reg_read_addr       <= mem_axi_araddr;
                reg_read_addr_valid <= 1'b1;
            end
            if (reg_do_read) begin
                reg_read_data[ 7: 0] <= mem[reg_read_addr + 0];
                reg_read_data[15: 8] <= mem[reg_read_addr + 1];
                reg_read_data[23:16] <= mem[reg_read_addr + 2];
                reg_read_data[31:24] <= mem[reg_read_addr + 3];
                reg_read_data_valid <= 1'b1;
            end
            if (mem_axi_rvalid && mem_axi_rready) begin
                reg_read_addr_valid <= 1'b0;
                reg_read_data_valid <= 1'b0;
            end
        end
    end

    assign mem_axi_arready    = !reg_read_addr_valid;
    assign mem_axi_rvalid     = reg_read_data_valid;
    assign mem_axi_rdata      = reg_read_data;

    assign dut_clk_en = !pause && !dut_stall;
    assign emu_dut_ff_clk_en = !pause && !dut_stall || ff_scan;
    assign emu_dut_ram_clk_en = !pause && !dut_stall || ram_scan;

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile(`DUMPFILE);
            $dumpvars();
        end
    end

    initial $readmemh("../../../design/picorv32/baremetal.hex", mem);

    always @(posedge clk)
        if (!resetn)
            count <= 64'd0;
        else if (count_write)
            count <= count_wdata;
        else if (dut_clk_en)
            count <= count + 64'd1;

    reg [63:0] step, step_next;

    always @(posedge clk)
        if (!resetn)
            step <= 64'd0;
        else
            step <= step_next;

    always @*
        if (step_write)
            step_next = step_wdata;
        else if (step == 64'd0)
            step_next = 64'd0;
        else if (dut_clk_en)
            step_next = step - 64'd1;

    assign step_trig = step != 64'd0 && step_next == 64'd0;

    always @(posedge clk)
        if (!resetn)
            pause <= 1'b0;
        else if (trig || step_trig || do_pause)
            pause <= 1'b1;
        else if (do_resume)
            pause <= 1'b0;

endmodule
