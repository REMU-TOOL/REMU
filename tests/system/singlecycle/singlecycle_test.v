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
    input   [11:0]  ctrl_bridge_s_axilite_araddr,
    input   [2:0]   ctrl_bridge_s_axilite_arprot,
    output          ctrl_bridge_s_axilite_rvalid,
    input           ctrl_bridge_s_axilite_rready,
    output  [1:0]   ctrl_bridge_s_axilite_rresp,
    output  [31:0]  ctrl_bridge_s_axilite_rdata,
    input           ctrl_bridge_s_axilite_awvalid,
    output          ctrl_bridge_s_axilite_awready,
    input   [11:0]  ctrl_bridge_s_axilite_awaddr,
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
        .host_clk                   (host_clk),
        .host_rst                   (host_rst),

        .ctrl_scanchain_dma_axi_arvalid              (ctrl_scanchain_dma_axi_arvalid),
        .ctrl_scanchain_dma_axi_arready              (ctrl_scanchain_dma_axi_arready),
        .ctrl_scanchain_dma_axi_araddr               (ctrl_scanchain_dma_axi_araddr),
        .ctrl_scanchain_dma_axi_arprot               (ctrl_scanchain_dma_axi_arprot),
        .ctrl_scanchain_dma_axi_arlen                (ctrl_scanchain_dma_axi_arlen),
        .ctrl_scanchain_dma_axi_arsize               (ctrl_scanchain_dma_axi_arsize),
        .ctrl_scanchain_dma_axi_arburst              (ctrl_scanchain_dma_axi_arburst),
        .ctrl_scanchain_dma_axi_arlock               (ctrl_scanchain_dma_axi_arlock),
        .ctrl_scanchain_dma_axi_arcache              (ctrl_scanchain_dma_axi_arcache),
        .ctrl_scanchain_dma_axi_rvalid               (ctrl_scanchain_dma_axi_rvalid),
        .ctrl_scanchain_dma_axi_rready               (ctrl_scanchain_dma_axi_rready),
        .ctrl_scanchain_dma_axi_rresp                (ctrl_scanchain_dma_axi_rresp),
        .ctrl_scanchain_dma_axi_rdata                (ctrl_scanchain_dma_axi_rdata),
        .ctrl_scanchain_dma_axi_rlast                (ctrl_scanchain_dma_axi_rlast),
        .ctrl_scanchain_dma_axi_awvalid              (ctrl_scanchain_dma_axi_awvalid),
        .ctrl_scanchain_dma_axi_awready              (ctrl_scanchain_dma_axi_awready),
        .ctrl_scanchain_dma_axi_awaddr               (ctrl_scanchain_dma_axi_awaddr),
        .ctrl_scanchain_dma_axi_awprot               (ctrl_scanchain_dma_axi_awprot),
        .ctrl_scanchain_dma_axi_awlen                (ctrl_scanchain_dma_axi_awlen),
        .ctrl_scanchain_dma_axi_awsize               (ctrl_scanchain_dma_axi_awsize),
        .ctrl_scanchain_dma_axi_awburst              (ctrl_scanchain_dma_axi_awburst),
        .ctrl_scanchain_dma_axi_awlock               (ctrl_scanchain_dma_axi_awlock),
        .ctrl_scanchain_dma_axi_awcache              (ctrl_scanchain_dma_axi_awcache),
        .ctrl_scanchain_dma_axi_wvalid               (ctrl_scanchain_dma_axi_wvalid),
        .ctrl_scanchain_dma_axi_wready               (ctrl_scanchain_dma_axi_wready),
        .ctrl_scanchain_dma_axi_wdata                (ctrl_scanchain_dma_axi_wdata_raw),
        .ctrl_scanchain_dma_axi_wstrb                (ctrl_scanchain_dma_axi_wstrb),
        .ctrl_scanchain_dma_axi_wlast                (ctrl_scanchain_dma_axi_wlast),
        .ctrl_scanchain_dma_axi_bvalid               (ctrl_scanchain_dma_axi_bvalid),
        .ctrl_scanchain_dma_axi_bready               (ctrl_scanchain_dma_axi_bready),
        .ctrl_scanchain_dma_axi_bresp                (ctrl_scanchain_dma_axi_bresp),

        .ctrl_bridge_s_axilite_arvalid          (ctrl_bridge_s_axilite_arvalid),
        .ctrl_bridge_s_axilite_arready          (ctrl_bridge_s_axilite_arready),
        .ctrl_bridge_s_axilite_araddr           (ctrl_bridge_s_axilite_araddr),
        .ctrl_bridge_s_axilite_arprot           (ctrl_bridge_s_axilite_arprot),
        .ctrl_bridge_s_axilite_rvalid           (ctrl_bridge_s_axilite_rvalid),
        .ctrl_bridge_s_axilite_rready           (ctrl_bridge_s_axilite_rready),
        .ctrl_bridge_s_axilite_rresp            (ctrl_bridge_s_axilite_rresp),
        .ctrl_bridge_s_axilite_rdata            (ctrl_bridge_s_axilite_rdata),
        .ctrl_bridge_s_axilite_awvalid          (ctrl_bridge_s_axilite_awvalid),
        .ctrl_bridge_s_axilite_awready          (ctrl_bridge_s_axilite_awready),
        .ctrl_bridge_s_axilite_awaddr           (ctrl_bridge_s_axilite_awaddr),
        .ctrl_bridge_s_axilite_awprot           (ctrl_bridge_s_axilite_awprot),
        .ctrl_bridge_s_axilite_wvalid           (ctrl_bridge_s_axilite_wvalid),
        .ctrl_bridge_s_axilite_wready           (ctrl_bridge_s_axilite_wready),
        .ctrl_bridge_s_axilite_wdata            (ctrl_bridge_s_axilite_wdata),
        .ctrl_bridge_s_axilite_wstrb            (ctrl_bridge_s_axilite_wstrb),
        .ctrl_bridge_s_axilite_bvalid           (ctrl_bridge_s_axilite_bvalid),
        .ctrl_bridge_s_axilite_bready           (ctrl_bridge_s_axilite_bready),
        .ctrl_bridge_s_axilite_bresp            (ctrl_bridge_s_axilite_bresp)
    );

    emu_top emu_ref();

    assign emu_ref.clock.clock = u_emu_system.target_clock_clock;
    assign emu_ref.reset.reset = u_emu_system.target_reset_reset;

    always @(posedge emu_ref.clock.clock) begin
        if (!emu_ref.reset.reset) begin
            if (u_emu_system.target.u_cpu.rf_wen !== emu_ref.u_cpu.rf_wen ||
                u_emu_system.target.u_cpu.rf_waddr !== emu_ref.u_cpu.rf_waddr ||
                u_emu_system.target.u_cpu.rf_wdata !== emu_ref.u_cpu.rf_wdata)
            begin
                $display("ERROR: trace mismatch");
                $display("DUT: wen=%h waddr=%h wdata=%h", u_emu_system.target.u_cpu.rf_wen, u_emu_system.target.u_cpu.rf_waddr, u_emu_system.target.u_cpu.rf_wdata);
                $display("REF: wen=%h waddr=%h wdata=%h", emu_ref.u_cpu.rf_wen, emu_ref.u_cpu.rf_waddr, emu_ref.u_cpu.rf_wdata);
                $fatal;
            end
        end
    end

endmodule
