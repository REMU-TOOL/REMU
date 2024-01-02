`timescale 1ns / 1ps

`include "axi.vh"

module axil_1x2_crossbar #(
    parameter S0_ADDR_BASE   = 40'h10000000,
    parameter S0_ADDR_OFFSET = 32'h10000000,
    parameter S1_ADDR_BASE   = 40'h20000000,
    parameter S1_ADDR_OFFSET = 32'h10000000,
    parameter MMIO_ADDR_WIDTH  = 32,
    parameter MMIO_DATA_WIDTH  = 32
) (
    input                       clk,
    input                       rst,
    `AXI4LITE_SLAVE_IF          (m0_axil,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH),
    `AXI4LITE_MASTER_IF         (s0_axil,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH),
    `AXI4LITE_MASTER_IF         (s1_axil,    MMIO_ADDR_WIDTH, MMIO_DATA_WIDTH)      
);
    reg channel_arbiter_read;
    reg channel_arbiter_write;

    always @(posedge clk) begin
        if(rst)
            channel_arbiter_read <= 0;
        else if(s1_axil_arready && s1_axil_arvalid)
            channel_arbiter_read <= 1;
        else if(s1_axil_rvalid && s1_axil_rready)
            channel_arbiter_read <= 0;
    end

    always @(posedge clk) begin
        if(rst)
            channel_arbiter_write <= 0;
        else if(s1_axil_awready && s1_axil_awvalid)
            channel_arbiter_write <= 1;
        else if(s1_axil_bvalid && s1_axil_bready)
            channel_arbiter_write <= 0;
    end

    wire read_in_s0_region  = (m0_axil_araddr <= (S0_ADDR_BASE+S0_ADDR_OFFSET)) && (m0_axil_araddr >= S0_ADDR_BASE);
    wire write_in_s0_region = (m0_axil_awaddr <= (S0_ADDR_BASE+S0_ADDR_OFFSET)) && (m0_axil_awaddr >= S0_ADDR_BASE);

    // AR 
    assign m0_axil_arready = (read_in_s0_region && s0_axil_arready) || (!read_in_s0_region && s1_axil_arready );
    assign s0_axil_arvalid = read_in_s0_region && m0_axil_arvalid;
    assign s1_axil_arvalid = !read_in_s0_region && m0_axil_arvalid;
    assign s0_axil_araddr  = m0_axil_araddr;
    assign s1_axil_araddr  = m0_axil_araddr;
    assign s0_axil_arprot  = m0_axil_arprot;
    assign s1_axil_arprot  = m0_axil_arprot;
    //AW
    assign m0_axil_awready = (write_in_s0_region && s0_axil_awready) || (!write_in_s0_region && s1_axil_awready );
    assign s0_axil_awvalid = write_in_s0_region && m0_axil_awvalid;
    assign s1_axil_awvalid = !write_in_s0_region && m0_axil_awvalid;
    assign s0_axil_awaddr  = m0_axil_awaddr;
    assign s1_axil_awaddr  = m0_axil_awaddr;
    assign s0_axil_awprot  = m0_axil_awprot;
    assign s1_axil_awprot  = m0_axil_awprot;
    //R
    assign m0_axil_rvalid  = channel_arbiter_read ? s1_axil_rvalid : s0_axil_rvalid;
    assign s0_axil_rready  = m0_axil_rready;
    assign s1_axil_rready  = m0_axil_rready;
    assign m0_axil_rdata   = channel_arbiter_read ? s1_axil_rdata : s0_axil_rdata;
    assign m0_axil_rresp   = channel_arbiter_read ? s1_axil_rresp : s0_axil_rresp;
    //W
    assign m0_axil_wready = (write_in_s0_region && s0_axil_wready) || (!write_in_s0_region && s1_axil_wready );
    assign s0_axil_wvalid = write_in_s0_region && m0_axil_wvalid;
    assign s1_axil_wvalid = !write_in_s0_region && m0_axil_wvalid;
    assign s0_axil_wdata  = m0_axil_wdata;
    assign s1_axil_wdata  = m0_axil_wdata;
    assign s0_axil_wstrb  = m0_axil_wstrb;
    assign s1_axil_wstrb  = m0_axil_wstrb;
    //B
    assign m0_axil_bvalid  = channel_arbiter_write ? s1_axil_bvalid : s0_axil_bvalid;
    assign s0_axil_bready  = m0_axil_bready;
    assign s1_axil_bready  = m0_axil_bready;
    assign m0_axil_bresp   = channel_arbiter_write ? s1_axil_bresp : s0_axil_bresp;

endmodule