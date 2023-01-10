`timescale 1 ns / 1 ns

module sim_x_to_0 #(
    parameter WIDTH = 1
)(
    input   [WIDTH-1:0] in,
    output  [WIDTH-1:0] out
);

    genvar i;
    for (i=0; i<WIDTH; i=i+1) begin
        assign out[i] = in[i] === 1'bx ? 1'b0 : in[i];
    end

endmodule

module sim_top(

    input           host_clk,
    input           host_rst,

    input           ctrl_bridge_s_axilite_arvalid,
    output          ctrl_bridge_s_axilite_arready,
    input   [15:0]  ctrl_bridge_s_axilite_araddr,
    input   [2:0]   ctrl_bridge_s_axilite_arprot,
    output          ctrl_bridge_s_axilite_rvalid,
    input           ctrl_bridge_s_axilite_rready,
    output  [1:0]   ctrl_bridge_s_axilite_rresp,
    output  [31:0]  ctrl_bridge_s_axilite_rdata,
    input           ctrl_bridge_s_axilite_awvalid,
    output          ctrl_bridge_s_axilite_awready,
    input   [15:0]  ctrl_bridge_s_axilite_awaddr,
    input   [2:0]   ctrl_bridge_s_axilite_awprot,
    input           ctrl_bridge_s_axilite_wvalid,
    output          ctrl_bridge_s_axilite_wready,
    input   [31:0]  ctrl_bridge_s_axilite_wdata,
    input   [3:0]   ctrl_bridge_s_axilite_wstrb,
    output          ctrl_bridge_s_axilite_bvalid,
    input           ctrl_bridge_s_axilite_bready,
    output  [1:0]   ctrl_bridge_s_axilite_bresp,

    output          ctrl_scanchain_dma_axi_awvalid,
    input           ctrl_scanchain_dma_axi_awready,
    output  [31:0]  ctrl_scanchain_dma_axi_awaddr,
    output  [0:0]   ctrl_scanchain_dma_axi_awid,
    output  [7:0]   ctrl_scanchain_dma_axi_awlen,
    output  [2:0]   ctrl_scanchain_dma_axi_awsize,
    output  [1:0]   ctrl_scanchain_dma_axi_awburst,
    output  [0:0]   ctrl_scanchain_dma_axi_awlock,
    output  [3:0]   ctrl_scanchain_dma_axi_awcache,
    output  [2:0]   ctrl_scanchain_dma_axi_awprot,
    output  [3:0]   ctrl_scanchain_dma_axi_awqos,
    output  [3:0]   ctrl_scanchain_dma_axi_awregion,
    output          ctrl_scanchain_dma_axi_wvalid,
    input           ctrl_scanchain_dma_axi_wready,
    output  [63:0]  ctrl_scanchain_dma_axi_wdata,
    output  [7:0]   ctrl_scanchain_dma_axi_wstrb,
    output          ctrl_scanchain_dma_axi_wlast,
    input           ctrl_scanchain_dma_axi_bvalid,
    output          ctrl_scanchain_dma_axi_bready,
    input   [1:0]   ctrl_scanchain_dma_axi_bresp,
    input   [0:0]   ctrl_scanchain_dma_axi_bid,
    output          ctrl_scanchain_dma_axi_arvalid,
    input           ctrl_scanchain_dma_axi_arready,
    output  [31:0]  ctrl_scanchain_dma_axi_araddr,
    output  [0:0]   ctrl_scanchain_dma_axi_arid,
    output  [7:0]   ctrl_scanchain_dma_axi_arlen,
    output  [2:0]   ctrl_scanchain_dma_axi_arsize,
    output  [1:0]   ctrl_scanchain_dma_axi_arburst,
    output  [0:0]   ctrl_scanchain_dma_axi_arlock,
    output  [3:0]   ctrl_scanchain_dma_axi_arcache,
    output  [2:0]   ctrl_scanchain_dma_axi_arprot,
    output  [3:0]   ctrl_scanchain_dma_axi_arqos,
    output  [3:0]   ctrl_scanchain_dma_axi_arregion,
    input           ctrl_scanchain_dma_axi_rvalid,
    output          ctrl_scanchain_dma_axi_rready,
    input   [63:0]  ctrl_scanchain_dma_axi_rdata,
    input   [1:0]   ctrl_scanchain_dma_axi_rresp,
    input   [0:0]   ctrl_scanchain_dma_axi_rid,
    input           ctrl_scanchain_dma_axi_rlast

);

    assign ctrl_scanchain_dma_axi_awid = 1'b0;
    assign ctrl_scanchain_dma_axi_arid = 1'b0;

    wire [63:0] ctrl_scanchain_dma_axi_wdata_raw;

    sim_x_to_0 #(.WIDTH(64)) wdata_x_to_0 (
        .in(ctrl_scanchain_dma_axi_wdata_raw),
        .out(ctrl_scanchain_dma_axi_wdata)
    );

    EMU_SYSTEM u_emu_system(
        .EMU_HOST_CLK                   (host_clk),
        .EMU_HOST_RST                   (host_rst),

        .EMU_SCAN_DMA_AXI_arvalid              (ctrl_scanchain_dma_axi_arvalid),
        .EMU_SCAN_DMA_AXI_arready              (ctrl_scanchain_dma_axi_arready),
        .EMU_SCAN_DMA_AXI_araddr               (ctrl_scanchain_dma_axi_araddr),
        .EMU_SCAN_DMA_AXI_arprot               (ctrl_scanchain_dma_axi_arprot),
        .EMU_SCAN_DMA_AXI_arlen                (ctrl_scanchain_dma_axi_arlen),
        .EMU_SCAN_DMA_AXI_arsize               (ctrl_scanchain_dma_axi_arsize),
        .EMU_SCAN_DMA_AXI_arburst              (ctrl_scanchain_dma_axi_arburst),
        .EMU_SCAN_DMA_AXI_arlock               (ctrl_scanchain_dma_axi_arlock),
        .EMU_SCAN_DMA_AXI_arcache              (ctrl_scanchain_dma_axi_arcache),
        .EMU_SCAN_DMA_AXI_rvalid               (ctrl_scanchain_dma_axi_rvalid),
        .EMU_SCAN_DMA_AXI_rready               (ctrl_scanchain_dma_axi_rready),
        .EMU_SCAN_DMA_AXI_rresp                (ctrl_scanchain_dma_axi_rresp),
        .EMU_SCAN_DMA_AXI_rdata                (ctrl_scanchain_dma_axi_rdata),
        .EMU_SCAN_DMA_AXI_rlast                (ctrl_scanchain_dma_axi_rlast),
        .EMU_SCAN_DMA_AXI_awvalid              (ctrl_scanchain_dma_axi_awvalid),
        .EMU_SCAN_DMA_AXI_awready              (ctrl_scanchain_dma_axi_awready),
        .EMU_SCAN_DMA_AXI_awaddr               (ctrl_scanchain_dma_axi_awaddr),
        .EMU_SCAN_DMA_AXI_awprot               (ctrl_scanchain_dma_axi_awprot),
        .EMU_SCAN_DMA_AXI_awlen                (ctrl_scanchain_dma_axi_awlen),
        .EMU_SCAN_DMA_AXI_awsize               (ctrl_scanchain_dma_axi_awsize),
        .EMU_SCAN_DMA_AXI_awburst              (ctrl_scanchain_dma_axi_awburst),
        .EMU_SCAN_DMA_AXI_awlock               (ctrl_scanchain_dma_axi_awlock),
        .EMU_SCAN_DMA_AXI_awcache              (ctrl_scanchain_dma_axi_awcache),
        .EMU_SCAN_DMA_AXI_wvalid               (ctrl_scanchain_dma_axi_wvalid),
        .EMU_SCAN_DMA_AXI_wready               (ctrl_scanchain_dma_axi_wready),
        .EMU_SCAN_DMA_AXI_wdata                (ctrl_scanchain_dma_axi_wdata_raw),
        .EMU_SCAN_DMA_AXI_wstrb                (ctrl_scanchain_dma_axi_wstrb),
        .EMU_SCAN_DMA_AXI_wlast                (ctrl_scanchain_dma_axi_wlast),
        .EMU_SCAN_DMA_AXI_bvalid               (ctrl_scanchain_dma_axi_bvalid),
        .EMU_SCAN_DMA_AXI_bready               (ctrl_scanchain_dma_axi_bready),
        .EMU_SCAN_DMA_AXI_bresp                (ctrl_scanchain_dma_axi_bresp),

        .EMU_CTRL_arvalid          (ctrl_bridge_s_axilite_arvalid),
        .EMU_CTRL_arready          (ctrl_bridge_s_axilite_arready),
        .EMU_CTRL_araddr           (ctrl_bridge_s_axilite_araddr),
        .EMU_CTRL_arprot           (ctrl_bridge_s_axilite_arprot),
        .EMU_CTRL_rvalid           (ctrl_bridge_s_axilite_rvalid),
        .EMU_CTRL_rready           (ctrl_bridge_s_axilite_rready),
        .EMU_CTRL_rresp            (ctrl_bridge_s_axilite_rresp),
        .EMU_CTRL_rdata            (ctrl_bridge_s_axilite_rdata),
        .EMU_CTRL_awvalid          (ctrl_bridge_s_axilite_awvalid),
        .EMU_CTRL_awready          (ctrl_bridge_s_axilite_awready),
        .EMU_CTRL_awaddr           (ctrl_bridge_s_axilite_awaddr),
        .EMU_CTRL_awprot           (ctrl_bridge_s_axilite_awprot),
        .EMU_CTRL_wvalid           (ctrl_bridge_s_axilite_wvalid),
        .EMU_CTRL_wready           (ctrl_bridge_s_axilite_wready),
        .EMU_CTRL_wdata            (ctrl_bridge_s_axilite_wdata),
        .EMU_CTRL_wstrb            (ctrl_bridge_s_axilite_wstrb),
        .EMU_CTRL_bvalid           (ctrl_bridge_s_axilite_bvalid),
        .EMU_CTRL_bready           (ctrl_bridge_s_axilite_bready),
        .EMU_CTRL_bresp            (ctrl_bridge_s_axilite_bresp)
    );

    EMU_ELAB emu_ref();

    assign emu_ref.clock.clock = u_emu_system.clock.clock;
    assign emu_ref.reset.reset = u_emu_system.reset.reset;

    always @(posedge emu_ref.clock.clock) begin
        if (!emu_ref.reset.reset) begin
            if (u_emu_system.u_cpu.rf_wen !== emu_ref.u_cpu.rf_wen ||
                u_emu_system.u_cpu.rf_waddr !== emu_ref.u_cpu.rf_waddr ||
                u_emu_system.u_cpu.rf_wdata !== emu_ref.u_cpu.rf_wdata)
            begin
                $display("ERROR: trace mismatch");
                $display("DUT: wen=%h waddr=%h wdata=%h", u_emu_system.u_cpu.rf_wen, u_emu_system.u_cpu.rf_waddr, u_emu_system.u_cpu.rf_wdata);
                $display("REF: wen=%h waddr=%h wdata=%h", emu_ref.u_cpu.rf_wen, emu_ref.u_cpu.rf_waddr, emu_ref.u_cpu.rf_wdata);
                $fatal;
            end
        end
    end

endmodule
