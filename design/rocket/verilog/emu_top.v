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

    ExampleRocketSystem rocket(
        .clock                                  (clk),
        .reset                                  (rst),
        .mem_axi4_0_aw_ready                    (io_mem_awready),
        .mem_axi4_0_aw_valid                    (io_mem_awvalid),
        .mem_axi4_0_aw_bits_id                  (io_mem_awid),
        .mem_axi4_0_aw_bits_addr                (io_mem_awaddr),
        .mem_axi4_0_aw_bits_len                 (io_mem_awlen),
        .mem_axi4_0_aw_bits_size                (io_mem_awsize),
        .mem_axi4_0_aw_bits_burst               (io_mem_awburst),
        .mem_axi4_0_aw_bits_lock                (io_mem_awlock),
        .mem_axi4_0_aw_bits_cache               (io_mem_awcache),
        .mem_axi4_0_aw_bits_prot                (io_mem_awprot),
        .mem_axi4_0_aw_bits_qos                 (io_mem_awqos),
        .mem_axi4_0_w_ready                     (io_mem_wready),
        .mem_axi4_0_w_valid                     (io_mem_wvalid),
        .mem_axi4_0_w_bits_data                 (io_mem_wdata),
        .mem_axi4_0_w_bits_strb                 (io_mem_wstrb),
        .mem_axi4_0_w_bits_last                 (io_mem_wlast),
        .mem_axi4_0_b_ready                     (io_mem_bready),
        .mem_axi4_0_b_valid                     (io_mem_bvalid),
        .mem_axi4_0_b_bits_id                   (io_mem_bid),
        .mem_axi4_0_b_bits_resp                 (io_mem_bresp),
        .mem_axi4_0_ar_ready                    (io_mem_arready),
        .mem_axi4_0_ar_valid                    (io_mem_arvalid),
        .mem_axi4_0_ar_bits_id                  (io_mem_arid),
        .mem_axi4_0_ar_bits_addr                (io_mem_araddr),
        .mem_axi4_0_ar_bits_len                 (io_mem_arlen),
        .mem_axi4_0_ar_bits_size                (io_mem_arsize),
        .mem_axi4_0_ar_bits_burst               (io_mem_arburst),
        .mem_axi4_0_ar_bits_lock                (io_mem_arlock),
        .mem_axi4_0_ar_bits_cache               (io_mem_arcache),
        .mem_axi4_0_ar_bits_prot                (io_mem_arprot),
        .mem_axi4_0_ar_bits_qos                 (io_mem_arqos),
        .mem_axi4_0_r_ready                     (io_mem_rready),
        .mem_axi4_0_r_valid                     (io_mem_rvalid),
        .mem_axi4_0_r_bits_id                   (io_mem_rid),
        .mem_axi4_0_r_bits_data                 (io_mem_rdata),
        .mem_axi4_0_r_bits_resp                 (io_mem_rresp),
        .mem_axi4_0_r_bits_last                 (io_mem_rlast),
        .mmio_axi4_0_aw_ready                   (io_mmio_awready),
        .mmio_axi4_0_aw_valid                   (io_mmio_awvalid),
        .mmio_axi4_0_aw_bits_id                 (io_mmio_awid),
        .mmio_axi4_0_aw_bits_addr               (io_mmio_awaddr),
        .mmio_axi4_0_aw_bits_len                (io_mmio_awlen),
        .mmio_axi4_0_aw_bits_size               (io_mmio_awsize),
        .mmio_axi4_0_aw_bits_burst              (io_mmio_awburst),
        .mmio_axi4_0_aw_bits_lock               (io_mmio_awlock),
        .mmio_axi4_0_aw_bits_cache              (io_mmio_awcache),
        .mmio_axi4_0_aw_bits_prot               (io_mmio_awprot),
        .mmio_axi4_0_aw_bits_qos                (io_mmio_awqos),
        .mmio_axi4_0_w_ready                    (io_mmio_wready),
        .mmio_axi4_0_w_valid                    (io_mmio_wvalid),
        .mmio_axi4_0_w_bits_data                (io_mmio_wdata),
        .mmio_axi4_0_w_bits_strb                (io_mmio_wstrb),
        .mmio_axi4_0_w_bits_last                (io_mmio_wlast),
        .mmio_axi4_0_b_ready                    (io_mmio_bready),
        .mmio_axi4_0_b_valid                    (io_mmio_bvalid),
        .mmio_axi4_0_b_bits_id                  (io_mmio_bid),
        .mmio_axi4_0_b_bits_resp                (io_mmio_bresp),
        .mmio_axi4_0_ar_ready                   (io_mmio_arready),
        .mmio_axi4_0_ar_valid                   (io_mmio_arvalid),
        .mmio_axi4_0_ar_bits_id                 (io_mmio_arid),
        .mmio_axi4_0_ar_bits_addr               (io_mmio_araddr),
        .mmio_axi4_0_ar_bits_len                (io_mmio_arlen),
        .mmio_axi4_0_ar_bits_size               (io_mmio_arsize),
        .mmio_axi4_0_ar_bits_burst              (io_mmio_arburst),
        .mmio_axi4_0_ar_bits_lock               (io_mmio_arlock),
        .mmio_axi4_0_ar_bits_cache              (io_mmio_arcache),
        .mmio_axi4_0_ar_bits_prot               (io_mmio_arprot),
        .mmio_axi4_0_ar_bits_qos                (io_mmio_arqos),
        .mmio_axi4_0_r_ready                    (io_mmio_rready),
        .mmio_axi4_0_r_valid                    (io_mmio_rvalid),
        .mmio_axi4_0_r_bits_id                  (io_mmio_rid),
        .mmio_axi4_0_r_bits_data                (io_mmio_rdata),
        .mmio_axi4_0_r_bits_resp                (io_mmio_rresp),
        .mmio_axi4_0_r_bits_last                (io_mmio_rlast),
        .l2_frontend_bus_axi4_0_aw_ready        (),
        .l2_frontend_bus_axi4_0_aw_valid        (1'b0),
        .l2_frontend_bus_axi4_0_aw_bits_id      (),
        .l2_frontend_bus_axi4_0_aw_bits_addr    (),
        .l2_frontend_bus_axi4_0_aw_bits_len     (),
        .l2_frontend_bus_axi4_0_aw_bits_size    (),
        .l2_frontend_bus_axi4_0_aw_bits_burst   (),
        .l2_frontend_bus_axi4_0_aw_bits_lock    (),
        .l2_frontend_bus_axi4_0_aw_bits_cache   (),
        .l2_frontend_bus_axi4_0_aw_bits_prot    (),
        .l2_frontend_bus_axi4_0_aw_bits_qos     (),
        .l2_frontend_bus_axi4_0_w_ready         (),
        .l2_frontend_bus_axi4_0_w_valid         (1'b0),
        .l2_frontend_bus_axi4_0_w_bits_data     (),
        .l2_frontend_bus_axi4_0_w_bits_strb     (),
        .l2_frontend_bus_axi4_0_w_bits_last     (),
        .l2_frontend_bus_axi4_0_b_ready         (1'b0),
        .l2_frontend_bus_axi4_0_b_valid         (),
        .l2_frontend_bus_axi4_0_b_bits_id       (),
        .l2_frontend_bus_axi4_0_b_bits_resp     (),
        .l2_frontend_bus_axi4_0_ar_ready        (),
        .l2_frontend_bus_axi4_0_ar_valid        (1'b0),
        .l2_frontend_bus_axi4_0_ar_bits_id      (),
        .l2_frontend_bus_axi4_0_ar_bits_addr    (),
        .l2_frontend_bus_axi4_0_ar_bits_len     (),
        .l2_frontend_bus_axi4_0_ar_bits_size    (),
        .l2_frontend_bus_axi4_0_ar_bits_burst   (),
        .l2_frontend_bus_axi4_0_ar_bits_lock    (),
        .l2_frontend_bus_axi4_0_ar_bits_cache   (),
        .l2_frontend_bus_axi4_0_ar_bits_prot    (),
        .l2_frontend_bus_axi4_0_ar_bits_qos     (),
        .l2_frontend_bus_axi4_0_r_ready         (1'b0),
        .l2_frontend_bus_axi4_0_r_valid         (),
        .l2_frontend_bus_axi4_0_r_bits_id       (),
        .l2_frontend_bus_axi4_0_r_bits_data     (),
        .l2_frontend_bus_axi4_0_r_bits_resp     (),
        .l2_frontend_bus_axi4_0_r_bits_last     (),
        .resetctrl_hartIsInReset_0              (rst),
        .debug_clock                            (clk),
        .debug_reset                            (1'b1),
        .debug_clockeddmi_dmi_req_ready         (),
        .debug_clockeddmi_dmi_req_valid         (1'b0),
        .debug_clockeddmi_dmi_req_bits_addr     (),
        .debug_clockeddmi_dmi_req_bits_data     (),
        .debug_clockeddmi_dmi_req_bits_op       (),
        .debug_clockeddmi_dmi_resp_ready        (1'b0),
        .debug_clockeddmi_dmi_resp_valid        (),
        .debug_clockeddmi_dmi_resp_bits_data    (),
        .debug_clockeddmi_dmi_resp_bits_resp    (),
        .debug_clockeddmi_dmiClock              (clk),
        .debug_clockeddmi_dmiReset              (1'b1),
        .debug_ndreset                          (),
        .debug_dmactive                         (),
        .debug_dmactiveAck                      (1'b0)
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
        .TIMING_TYPE    ("fixed")
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
