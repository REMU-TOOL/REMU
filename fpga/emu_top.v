`include "emu_csr.vh"

module emu_top(
    input           clk,
    input           resetn,

    output          m_axi_arvalid,
    input           m_axi_arready,
    output  [63:0]  m_axi_araddr,
    output  [ 2:0]  m_axi_arprot,
    output  [ 7:0]  m_axi_arlen,
    output  [ 2:0]  m_axi_arsize,
    output  [ 1:0]  m_axi_arburst,
    output  [ 0:0]  m_axi_arlock,
    output  [ 3:0]  m_axi_arcache,
    input           m_axi_rvalid,
    output          m_axi_rready,
    input   [ 1:0]  m_axi_rresp,
    input   [63:0]  m_axi_rdata,
    input           m_axi_rlast,
    output          m_axi_awvalid,
    input           m_axi_awready,
    output  [63:0]  m_axi_awaddr,
    output  [ 2:0]  m_axi_awprot,
    output  [ 7:0]  m_axi_awlen,
    output  [ 2:0]  m_axi_awsize,
    output  [ 1:0]  m_axi_awburst,
    output  [ 0:0]  m_axi_awlock,
    output  [ 3:0]  m_axi_awcache,
    output          m_axi_wvalid,
    input           m_axi_wready,
    output  [63:0]  m_axi_wdata,
    output  [ 7:0]  m_axi_wstrb,
    output          m_axi_wlast,
    input           m_axi_bvalid,
    output          m_axi_bready,
    input   [ 1:0]  m_axi_bresp,

    input           s_axilite_arvalid,
    output          s_axilite_arready,
    input   [11:0]  s_axilite_araddr,
    input   [ 2:0]  s_axilite_arprot,
    output          s_axilite_rvalid,
    input           s_axilite_rready,
    output  [ 1:0]  s_axilite_rresp,
    output  [31:0]  s_axilite_rdata,
    input           s_axilite_awvalid,
    output          s_axilite_awready,
    input   [11:0]  s_axilite_awaddr,
    input   [ 2:0]  s_axilite_awprot,
    input           s_axilite_wvalid,
    output          s_axilite_wready,
    input   [31:0]  s_axilite_wdata,
    input   [ 3:0]  s_axilite_wstrb,
    output          s_axilite_bvalid,
    input           s_axilite_bready,
    output  [ 1:0]  s_axilite_bresp,

    input           s_axilite_emureg_arvalid,
    output          s_axilite_emureg_arready,
    input   [14:0]  s_axilite_emureg_araddr,
    input   [ 2:0]  s_axilite_emureg_arprot,
    output          s_axilite_emureg_rvalid,
    input           s_axilite_emureg_rready,
    output  [ 1:0]  s_axilite_emureg_rresp,
    output  [63:0]  s_axilite_emureg_rdata,
    input           s_axilite_emureg_awvalid,
    output          s_axilite_emureg_awready,
    input   [14:0]  s_axilite_emureg_awaddr,
    input   [ 2:0]  s_axilite_emureg_awprot,
    input           s_axilite_emureg_wvalid,
    output          s_axilite_emureg_wready,
    input   [63:0]  s_axilite_emureg_wdata,
    input   [ 7:0]  s_axilite_emureg_wstrb,
    output          s_axilite_emureg_bvalid,
    input           s_axilite_emureg_bready,
    output  [ 1:0]  s_axilite_emureg_bresp,

    input           s_axilite_idealmem_arvalid,
    output          s_axilite_idealmem_arready,
    input   [11:0]  s_axilite_idealmem_araddr,
    input   [ 2:0]  s_axilite_idealmem_arprot,
    output          s_axilite_idealmem_rvalid,
    input           s_axilite_idealmem_rready,
    output  [ 1:0]  s_axilite_idealmem_rresp,
    output  [31:0]  s_axilite_idealmem_rdata,
    input           s_axilite_idealmem_awvalid,
    output          s_axilite_idealmem_awready,
    input   [11:0]  s_axilite_idealmem_awaddr,
    input   [ 2:0]  s_axilite_idealmem_awprot,
    input           s_axilite_idealmem_wvalid,
    output          s_axilite_idealmem_wready,
    input   [31:0]  s_axilite_idealmem_wdata,
    input   [ 3:0]  s_axilite_idealmem_wstrb,
    output          s_axilite_idealmem_bvalid,
    input           s_axilite_idealmem_bready,
    output  [ 1:0]  s_axilite_idealmem_bresp
);

    wire rst = !resetn;

    /*
     * AXI read descriptor input
     */
    wire            s_axis_read_desc_valid;
    wire            s_axis_read_desc_ready;

    /*
     * AXI read descriptor status output
     */
    wire [3:0]      m_axis_read_desc_status_error;
    wire            m_axis_read_desc_status_valid;

    /*
     * AXI stream read data output
     */
    wire [63:0]     m_axis_read_data_tdata;
    wire            m_axis_read_data_tvalid;
    wire            m_axis_read_data_tready;
    wire            m_axis_read_data_tlast;

    /*
     * AXI write descriptor input
     */
    wire            s_axis_write_desc_valid;
    wire            s_axis_write_desc_ready;

    /*
     * AXI write descriptor status output
     */
    wire [19:0]     m_axis_write_desc_status_len;
    wire [3:0]      m_axis_write_desc_status_error;
    wire            m_axis_write_desc_status_valid;

    /*
     * AXI stream write data input
     */
    wire [63:0]     s_axis_write_data_tdata;
    wire            s_axis_write_data_tvalid;
    wire            s_axis_write_data_tready;
    wire            s_axis_write_data_tlast;

    // CSR write logic

    reg [11:0] reg_write_addr;
    reg [31:0] reg_write_data;
    reg reg_write_addr_valid, reg_write_data_valid, reg_write_error, reg_write_resp_valid;
    wire reg_write_addr_data_ok = reg_write_addr_valid && reg_write_data_valid;
    wire reg_do_write = reg_write_addr_data_ok && !reg_write_error;

    always @(posedge clk) begin
        if (rst) begin
            reg_write_addr          <= 12'd0;
            reg_write_data          <= 32'd0;
            reg_write_addr_valid    <= 1'b0;
            reg_write_data_valid    <= 1'b0;
            reg_write_error         <= 1'b0;
            reg_write_resp_valid    <= 1'b0;
        end
        else begin
            if (s_axilite_awvalid && s_axilite_awready) begin
                reg_write_addr          <= s_axilite_awaddr;
                reg_write_addr_valid    <= 1'b1;
            end
            if (s_axilite_wvalid && s_axilite_wready) begin
                reg_write_data          <= s_axilite_wdata;
                reg_write_data_valid    <= 1'b1;
                reg_write_error         <= s_axilite_wstrb != 4'b1111;
            end
            if (reg_write_addr_data_ok) begin
                reg_write_addr_valid    <= 1'b0;
                reg_write_data_valid    <= 1'b0;
                reg_write_resp_valid    <= 1'b1;
            end
            if (s_axilite_bvalid && s_axilite_bready) begin
                reg_write_resp_valid    <= 1'b0;
            end
        end
    end

    assign s_axilite_awready    = !reg_write_addr_valid;
    assign s_axilite_wready     = !reg_write_data_valid;
    assign s_axilite_bvalid     = reg_write_resp_valid;
    assign s_axilite_bresp      = reg_write_error ? 2'b10 : 2'b00;

    // EMU_STAT
    //      [0]     -> HALT
    //      [1]     -> DUT_RESET
    // EMU_CTRL
    //      [0]     -> SCAN_IN_PREP [WO]
    //      [1]     -> SCAN_OUT_PREP [WO]

    reg emu_halt, emu_dut_reset, emu_scan_in_prep, emu_scan_out_prep;
    wire [31:0] emu_stat, emu_ctrl;
    assign emu_stat[31:2]   = 31'd0;
    assign emu_stat[1]      = emu_dut_reset;
    assign emu_stat[0]      = emu_halt;
    assign emu_ctrl         = 32'd0;

    wire trigger;

    always @(posedge clk) begin
        if (rst) begin
            emu_halt            <= 1'b1;
            emu_dut_reset       <= 1'b1;
        end
        else if (trigger) begin
            emu_halt            <= 1'b1;
        end
        else begin
            if (reg_do_write && reg_write_addr == `EMU_STAT) begin
                emu_halt            <= reg_write_data[0];
                emu_dut_reset       <= reg_write_data[1];
            end
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            emu_scan_in_prep    <= 1'b0;
            emu_scan_out_prep   <= 1'b0;
        end
        else begin
            if (emu_scan_in_prep) begin
                emu_scan_in_prep    <= 1'b0;
            end
            if (emu_scan_out_prep) begin
                emu_scan_out_prep   <= 1'b0;
            end
            if (reg_do_write && reg_write_addr == `EMU_CTRL) begin
                emu_scan_in_prep    <= reg_write_data[0];
                emu_scan_out_prep   <= reg_write_data[1];
            end
        end
    end

    // EMU_CYCLE_LO
    // EMU_CYCLE_HI

    reg [63:0] emu_cycle;

    always @(posedge clk) begin
        if (rst) begin
            emu_cycle <= 64'd0;
        end
        else if (!emu_halt) begin
            emu_cycle <= emu_cycle + 64'd1;
        end
        else begin
            if (reg_do_write && reg_write_addr == `EMU_CYCLE_LO) begin
                emu_cycle[31:0] <= reg_write_data;
            end
            if (reg_do_write && reg_write_addr == `EMU_CYCLE_HI) begin
                emu_cycle[63:32] <= reg_write_data;
            end
        end
    end

    // EMU_STEP

    reg [31:0] emu_step, emu_step_next;

    always @* begin
        if (emu_halt) begin
            emu_step_next = emu_step;
        end
        else if (emu_step != 32'd0) begin
            emu_step_next = emu_step - 32'd1;
        end
        else begin
            emu_step_next = 32'd0;
        end
    end

    wire step_trigger = emu_step != 32'd0 && emu_step_next == 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            emu_step <= 32'd0;
        end
        else if (reg_do_write && reg_write_addr == `EMU_STEP) begin
            emu_step <= reg_write_data;
        end
        else begin
            emu_step <= emu_step_next;
        end
    end

    // EMU_DMA_RD_ADDR_LO
    // EMU_DMA_RD_ADDR_HI
    // EMU_DMA_RD_LEN
    //      [19:0]  -> LEN
    // EMU_DMA_RD_CSR
    //      [0]     -> START [WO] / RUNNING [RO]
    //      [4:1]   -> ERROR [RO]

    reg [63:0] emu_dma_rd_addr;
    reg [19:0] emu_dma_rd_len;
    reg emu_dma_rd_start, emu_dma_rd_running;
    reg [3:0] emu_dma_rd_error;
    wire [31:0] emu_dma_rd_csr;
    assign emu_dma_rd_csr[31:5] = 27'd0;
    assign emu_dma_rd_csr[4:1]  = emu_dma_rd_error;
    assign emu_dma_rd_csr[0]    = emu_dma_rd_running;

    always @(posedge clk) begin
        if (rst) begin
            emu_dma_rd_addr     <= 64'd0;
            emu_dma_rd_len      <= 20'd0;
            emu_dma_rd_start    <= 1'b0;
            emu_dma_rd_running  <= 1'b0;
            emu_dma_rd_error    <= 4'd0;
        end
        else begin
            if (s_axis_read_desc_valid && s_axis_read_desc_ready) begin
                emu_dma_rd_start        <= 1'b0;
            end
            if (m_axis_read_desc_status_valid) begin
                emu_dma_rd_running      <= 1'b0;
                emu_dma_rd_error        <= m_axis_read_desc_status_error;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_RD_ADDR_LO) begin
                emu_dma_rd_addr[31:0]   <= reg_write_data;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_RD_ADDR_HI) begin
                emu_dma_rd_addr[63:32]  <= reg_write_data;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_RD_LEN) begin
                emu_dma_rd_len          <= reg_write_data[19:0];
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_RD_CSR) begin
                emu_dma_rd_start        <= emu_dma_rd_start || reg_write_data[0];
                emu_dma_rd_running      <= emu_dma_rd_running || reg_write_data[0];
            end
        end
    end

    assign s_axis_read_desc_valid   = emu_dma_rd_start;

    // EMU_DMA_WR_ADDR_LO
    // EMU_DMA_WR_ADDR_HI
    // EMU_DMA_WR_LEN
    //      [19:0]  -> LEN
    // EMU_DMA_WR_CSR
    //      [0]     -> START [WO] / RUNNING [RO]
    //      [4:1]   -> ERROR [RO]

    reg [63:0] emu_dma_wr_addr;
    reg [19:0] emu_dma_wr_len;
    reg emu_dma_wr_start, emu_dma_wr_running;
    reg [3:0] emu_dma_wr_error;
    wire [31:0] emu_dma_wr_csr;
    assign emu_dma_wr_csr[31:5] = 27'd0;
    assign emu_dma_wr_csr[4:1]  = emu_dma_wr_error;
    assign emu_dma_wr_csr[0]    = emu_dma_wr_running;

    always @(posedge clk) begin
        if (rst) begin
            emu_dma_wr_addr     <= 64'd0;
            emu_dma_wr_len      <= 20'd0;
            emu_dma_wr_start    <= 1'b0;
            emu_dma_wr_running  <= 1'b0;
            emu_dma_wr_error    <= 4'd0;
        end
        else begin
            if (s_axis_write_desc_valid && s_axis_write_desc_ready) begin
                emu_dma_wr_start        <= 1'b0;
            end
            if (m_axis_write_desc_status_valid) begin
                emu_dma_wr_len          <= m_axis_write_desc_status_len;
                emu_dma_wr_running      <= 1'b0;
                emu_dma_wr_error        <= m_axis_write_desc_status_error;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_WR_ADDR_LO) begin
                emu_dma_wr_addr[31:0]   <= reg_write_data;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_WR_ADDR_HI) begin
                emu_dma_wr_addr[63:32]  <= reg_write_data;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_WR_LEN) begin
                emu_dma_wr_len          <= reg_write_data[19:0];
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_WR_CSR) begin
                emu_dma_wr_start        <= emu_dma_wr_start || reg_write_data[0];
                emu_dma_wr_running      <= emu_dma_wr_running || reg_write_data[0];
            end
        end
    end

    assign s_axis_write_desc_valid  = emu_dma_wr_start;

    // CSR read logic

    reg [11:0] reg_read_addr;
    reg [31:0] reg_read_data, reg_read_data_wire;
    reg reg_read_addr_valid, reg_read_data_valid;
    wire reg_do_read = reg_read_addr_valid && !reg_read_data_valid;

    always @* begin
        case (reg_read_addr)
            `EMU_STAT:              reg_read_data_wire = emu_stat;
            `EMU_CTRL:              reg_read_data_wire = emu_ctrl;
            `EMU_CYCLE_LO:          reg_read_data_wire = emu_cycle[31:0];
            `EMU_CYCLE_HI:          reg_read_data_wire = emu_cycle[63:32];
            `EMU_STEP:              reg_read_data_wire = emu_step;
            `EMU_DMA_RD_ADDR_LO:    reg_read_data_wire = emu_dma_rd_addr[31:0];
            `EMU_DMA_RD_ADDR_HI:    reg_read_data_wire = emu_dma_rd_addr[63:32];
            `EMU_DMA_RD_LEN:        reg_read_data_wire = {12'd0, emu_dma_rd_len};
            `EMU_DMA_RD_CSR:        reg_read_data_wire = emu_dma_rd_csr;
            `EMU_DMA_WR_ADDR_LO:    reg_read_data_wire = emu_dma_wr_addr[31:0];
            `EMU_DMA_WR_ADDR_HI:    reg_read_data_wire = emu_dma_wr_addr[63:32];
            `EMU_DMA_WR_LEN:        reg_read_data_wire = {12'd0, emu_dma_wr_len};
            `EMU_DMA_WR_CSR:        reg_read_data_wire = emu_dma_wr_csr;
            default:                reg_read_data_wire = 32'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            reg_read_addr       <= 12'd0;
            reg_read_data       <= 32'd0;
            reg_read_addr_valid <= 1'b0;
            reg_read_data_valid <= 1'b0;
        end
        else begin
            if (s_axilite_arvalid && s_axilite_arready) begin
                reg_read_addr       <= s_axilite_araddr;
                reg_read_addr_valid <= 1'b1;
            end
            if (reg_do_read) begin
                reg_read_data       <= reg_read_data_wire;
                reg_read_data_valid <= 1'b1;
            end
            if (s_axilite_rvalid && s_axilite_rready) begin
                reg_read_addr_valid <= 1'b0;
                reg_read_data_valid <= 1'b0;
            end
        end
    end

    assign s_axilite_arready    = !reg_read_addr_valid;
    assign s_axilite_rvalid     = reg_read_data_valid;
    assign s_axilite_rdata      = reg_read_data;
    assign s_axilite_rresp      = 2'b00;

    // DMA for scan chain

    axi_dma #(
        .AXI_DATA_WIDTH                 (64),
        .AXI_ADDR_WIDTH                 (64),
        .AXI_ID_WIDTH                   (1),
        .AXIS_USER_ENABLE               (0)
    )
    u_dma(
        .clk                            (clk),
        .rst                            (rst),

        /*
        * AXI read descriptor input
        */
        .s_axis_read_desc_addr          (emu_dma_rd_addr),
        .s_axis_read_desc_len           (emu_dma_rd_len),
        .s_axis_read_desc_tag           (8'd0),
        .s_axis_read_desc_id            (8'd0),
        .s_axis_read_desc_dest          (8'd0),
        .s_axis_read_desc_user          (1'd0),
        .s_axis_read_desc_valid         (s_axis_read_desc_valid),
        .s_axis_read_desc_ready         (s_axis_read_desc_ready),

        /*
        * AXI read descriptor status output
        */
        .m_axis_read_desc_status_tag    (),
        .m_axis_read_desc_status_error  (m_axis_read_desc_status_error),
        .m_axis_read_desc_status_valid  (m_axis_read_desc_status_valid),

        /*
        * AXI stream read data output
        */
        .m_axis_read_data_tdata         (m_axis_read_data_tdata),
        .m_axis_read_data_tkeep         (),
        .m_axis_read_data_tvalid        (m_axis_read_data_tvalid),
        .m_axis_read_data_tready        (m_axis_read_data_tready),
        .m_axis_read_data_tlast         (m_axis_read_data_tlast),
        .m_axis_read_data_tid           (),
        .m_axis_read_data_tdest         (),
        .m_axis_read_data_tuser         (),

        /*
        * AXI write descriptor input
        */
        .s_axis_write_desc_addr         (emu_dma_wr_addr),
        .s_axis_write_desc_len          (emu_dma_wr_len),
        .s_axis_write_desc_tag          (8'd0),
        .s_axis_write_desc_valid        (s_axis_write_desc_valid),
        .s_axis_write_desc_ready        (s_axis_write_desc_ready),

        /*
        * AXI write descriptor status output
        */
        .m_axis_write_desc_status_len   (m_axis_write_desc_status_len),
        .m_axis_write_desc_status_tag   (),
        .m_axis_write_desc_status_id    (),
        .m_axis_write_desc_status_dest  (),
        .m_axis_write_desc_status_user  (),
        .m_axis_write_desc_status_error (m_axis_write_desc_status_error),
        .m_axis_write_desc_status_valid (m_axis_write_desc_status_valid),

        /*
        * AXI stream write data input
        */
        .s_axis_write_data_tdata        (s_axis_write_data_tdata),
        .s_axis_write_data_tkeep        (8'b11111111),
        .s_axis_write_data_tvalid       (s_axis_write_data_tvalid),
        .s_axis_write_data_tready       (s_axis_write_data_tready),
        .s_axis_write_data_tlast        (s_axis_write_data_tlast),
        .s_axis_write_data_tid          (8'd0),
        .s_axis_write_data_tdest        (8'd0),
        .s_axis_write_data_tuser        (1'd0),

        /*
        * AXI master interface
        */
        .m_axi_arid                     (),
        .m_axi_araddr                   (m_axi_araddr),
        .m_axi_arlen                    (m_axi_arlen),
        .m_axi_arsize                   (m_axi_arsize),
        .m_axi_arburst                  (m_axi_arburst),
        .m_axi_arlock                   (m_axi_arlock),
        .m_axi_arcache                  (m_axi_arcache),
        .m_axi_arprot                   (m_axi_arprot),
        .m_axi_arvalid                  (m_axi_arvalid),
        .m_axi_arready                  (m_axi_arready),
        .m_axi_rid                      (1'd0),
        .m_axi_rdata                    (m_axi_rdata),
        .m_axi_rresp                    (m_axi_rresp),
        .m_axi_rlast                    (m_axi_rlast),
        .m_axi_rvalid                   (m_axi_rvalid),
        .m_axi_rready                   (m_axi_rready),
        .m_axi_awid                     (),
        .m_axi_awaddr                   (m_axi_awaddr),
        .m_axi_awlen                    (m_axi_awlen),
        .m_axi_awsize                   (m_axi_awsize),
        .m_axi_awburst                  (m_axi_awburst),
        .m_axi_awlock                   (m_axi_awlock),
        .m_axi_awcache                  (m_axi_awcache),
        .m_axi_awprot                   (m_axi_awprot),
        .m_axi_awvalid                  (m_axi_awvalid),
        .m_axi_awready                  (m_axi_awready),
        .m_axi_wdata                    (m_axi_wdata),
        .m_axi_wstrb                    (m_axi_wstrb),
        .m_axi_wlast                    (m_axi_wlast),
        .m_axi_wvalid                   (m_axi_wvalid),
        .m_axi_wready                   (m_axi_wready),
        .m_axi_bid                      (1'd0),
        .m_axi_bresp                    (m_axi_bresp),
        .m_axi_bvalid                   (m_axi_bvalid),
        .m_axi_bready                   (m_axi_bready),

        /*
        * Configuration
        */
        .read_enable                    (emu_dma_rd_running),
        .write_enable                   (emu_dma_wr_running),
        .write_abort                    (1'b0)
    );

    reg [14:0] emureg_read_addr, emureg_write_addr;
    reg [63:0] emureg_read_data, emureg_write_data;
    reg emureg_read_addr_valid, emureg_read_data_valid, emureg_write_addr_valid, emureg_write_data_valid, emureg_write_resp_valid;
    wire emureg_do_write = emureg_write_addr_valid && emureg_write_data_valid;
    wire [63:0] emureg_read_data_wire;

    always @(posedge clk) begin
        if (rst) begin
            emureg_read_addr          <= 12'd0;
            emureg_write_addr         <= 12'd0;
            emureg_read_data          <= 64'd0;
            emureg_write_data         <= 64'd0;
            emureg_read_addr_valid    <= 1'b0;
            emureg_read_data_valid    <= 1'b0;
            emureg_write_addr_valid   <= 1'b0;
            emureg_write_data_valid   <= 1'b0;
            emureg_write_resp_valid   <= 1'b0;
        end
        else begin
            if (s_axilite_emureg_arvalid && s_axilite_emureg_arready) begin
                emureg_read_addr          <= s_axilite_emureg_araddr;
                emureg_read_addr_valid    <= 1'b1;
            end
            if (emureg_read_addr_valid) begin
                emureg_read_data          <= emureg_read_data_wire;
                emureg_read_data_valid    <= 1'b1;
            end
            if (s_axilite_emureg_rvalid && s_axilite_emureg_rready) begin
                emureg_read_addr_valid    <= 1'b0;
                emureg_read_data_valid    <= 1'b0;
            end
            if (s_axilite_emureg_awvalid && s_axilite_emureg_awready) begin
                emureg_write_addr         <= s_axilite_emureg_awaddr;
                emureg_write_addr_valid   <= 1'b1;
            end
            if (s_axilite_emureg_wvalid && s_axilite_emureg_wready) begin
                emureg_write_data         <= s_axilite_emureg_wdata;
                emureg_write_data_valid   <= 1'b1;
            end
            if (emureg_do_write) begin
                emureg_write_addr_valid   <= 1'b0;
                emureg_write_data_valid   <= 1'b0;
                emureg_write_resp_valid   <= 1'b1;
            end
            if (s_axilite_emureg_bvalid && s_axilite_emureg_bready) begin
                emureg_write_resp_valid   <= 1'b0;
            end
        end
    end

    assign s_axilite_emureg_arready   = !emureg_read_addr_valid;
    assign s_axilite_emureg_rvalid    = emureg_read_data_valid;
    assign s_axilite_emureg_rdata     = emureg_read_data;
    assign s_axilite_emureg_rresp     = 2'd0;
    assign s_axilite_emureg_awready   = !emureg_write_addr_valid;
    assign s_axilite_emureg_wready    = !emureg_write_data_valid;
    assign s_axilite_emureg_bvalid    = emureg_write_resp_valid;
    assign s_axilite_emureg_bresp     = 2'd0;

    wire [31:0] PC;
    wire [31:0] Instruction;
    wire [31:0] Address;
    wire MemWrite;
    wire [31:0] Write_data;
    wire [3:0] Write_strb;
    wire MemRead;
    wire [31:0] Read_data;

    mips_cpu u_cpu ( 
        .clk                (clk),
        .rst                (emu_dut_reset),
        .PC                 (PC),
        .Instruction        (Instruction),
        .Address            (Address),
        .MemWrite           (MemWrite),
        .Write_data         (Write_data),
        .Write_strb         (Write_strb),
        .MemRead            (MemRead),
        .Read_data          (Read_data),
        .\$EMU$RESET        (rst),
        .\$EMU$HALT         (emu_halt),
        .\$EMU$RADDR        (emureg_read_addr[14:3]),
        .\$EMU$RDATA        (emureg_read_data_wire),
        .\$EMU$WADDR        (emureg_write_addr[14:3]),
        .\$EMU$WDATA        (emureg_write_data),
        .\$EMU$WEN          ({64{emureg_do_write}}),
        .\$EMU$RAM$RDATA    (s_axis_write_data_tdata),
        .\$EMU$RAM$RID      (12'd0),
        .\$EMU$RAM$RLAST    (s_axis_write_data_tlast),
        .\$EMU$RAM$RREADY   (s_axis_write_data_tready),
        .\$EMU$RAM$RREQ     (emu_scan_out_prep),
        .\$EMU$RAM$RVALID   (s_axis_write_data_tvalid),
        .\$EMU$RAM$WDATA    (m_axis_read_data_tdata),
        .\$EMU$RAM$WID      (12'd0),
        .\$EMU$RAM$WLAST    (m_axis_read_data_tlast),
        .\$EMU$RAM$WREADY   (m_axis_read_data_tready),
        .\$EMU$RAM$WREQ     (emu_scan_in_prep),
        .\$EMU$RAM$WVALID   (m_axis_read_data_tvalid)
    );

    wire user_trigger = MemWrite && Address == 32'h0000000c;

    reg [11:0] idealmem_read_addr, idealmem_write_addr;
    reg [31:0] idealmem_read_data, idealmem_write_data;
    reg [3:0] idealmem_write_strb;
    reg idealmem_read_addr_valid, idealmem_read_data_valid, idealmem_write_addr_valid, idealmem_write_data_valid, idealmem_write_resp_valid;
    wire idealmem_do_write = idealmem_write_addr_valid && idealmem_write_data_valid;
    wire [31:0] idealmem_read_data_wire;

    always @(posedge clk) begin
        if (rst) begin
            idealmem_read_addr          <= 12'd0;
            idealmem_write_addr         <= 12'd0;
            idealmem_read_data          <= 32'd0;
            idealmem_write_data         <= 32'd0;
            idealmem_write_strb         <= 4'd0;
            idealmem_read_addr_valid    <= 1'b0;
            idealmem_read_data_valid    <= 1'b0;
            idealmem_write_addr_valid   <= 1'b0;
            idealmem_write_data_valid   <= 1'b0;
            idealmem_write_resp_valid   <= 1'b0;
        end
        else begin
            if (s_axilite_idealmem_arvalid && s_axilite_idealmem_arready) begin
                idealmem_read_addr          <= s_axilite_idealmem_araddr;
                idealmem_read_addr_valid    <= 1'b1;
            end
            if (idealmem_read_addr_valid) begin
                idealmem_read_data          <= idealmem_read_data_wire;
                idealmem_read_data_valid    <= 1'b1;
            end
            if (s_axilite_idealmem_rvalid && s_axilite_idealmem_rready) begin
                idealmem_read_addr_valid    <= 1'b0;
                idealmem_read_data_valid    <= 1'b0;
            end
            if (s_axilite_idealmem_awvalid && s_axilite_idealmem_awready) begin
                idealmem_write_addr         <= s_axilite_idealmem_awaddr;
                idealmem_write_addr_valid   <= 1'b1;
            end
            if (s_axilite_idealmem_wvalid && s_axilite_idealmem_wready) begin
                idealmem_write_data         <= s_axilite_idealmem_wdata;
                idealmem_write_strb         <= s_axilite_idealmem_wstrb;
                idealmem_write_data_valid   <= 1'b1;
            end
            if (idealmem_do_write) begin
                idealmem_write_addr_valid   <= 1'b0;
                idealmem_write_data_valid   <= 1'b0;
                idealmem_write_resp_valid   <= 1'b1;
            end
            if (s_axilite_idealmem_bvalid && s_axilite_idealmem_bready) begin
                idealmem_write_resp_valid   <= 1'b0;
            end
        end
    end

    assign s_axilite_idealmem_arready   = !idealmem_read_addr_valid;
    assign s_axilite_idealmem_rvalid    = idealmem_read_data_valid;
    assign s_axilite_idealmem_rdata     = idealmem_read_data;
    assign s_axilite_idealmem_rresp     = 2'd0;
    assign s_axilite_idealmem_awready   = !idealmem_write_addr_valid;
    assign s_axilite_idealmem_wready    = !idealmem_write_data_valid;
    assign s_axilite_idealmem_bvalid    = idealmem_write_resp_valid;
    assign s_axilite_idealmem_bresp     = 2'd0;

    wire mux_wen = emu_halt ? idealmem_do_write : MemWrite;
    wire [9:0] mux_waddr = emu_halt ? idealmem_write_addr[11:2] : Address[11:2];
    wire [31:0] mux_wdata = emu_halt ? idealmem_write_data : Write_data;
    wire [3:0] mux_wstrb = emu_halt ? idealmem_write_strb : Write_strb;
    wire [9:0] mux_raddr = emu_halt ? idealmem_read_addr[11:2] : Address[11:2];
    wire [31:0] mux_rdata;

    ideal_mem #(.WIDTH(32), .DEPTH(1024)) u_mem (
        .clk                (clk),
        .wen1               (mux_wen),
        .waddr1             (mux_waddr),
        .wdata1             (mux_wdata),
        .wstrb1             (mux_wstrb),
        .raddr1             (PC[11:2]),
        .rdata1             (Instruction),
        .raddr2             (mux_raddr),
        .rdata2             (mux_rdata)
    );

    assign Read_data = mux_rdata;
    assign idealmem_read_data_wire = mux_rdata;

    assign trigger = step_trigger || user_trigger;

endmodule

module ideal_mem #(
    parameter WIDTH = 32,
    parameter DEPTH = 1024,
    parameter AWIDTH = $clog2(DEPTH)
)(
    input clk,
    input wen1,
    input [AWIDTH-1:0] waddr1,
    input [WIDTH-1:0] wdata1,
    input [WIDTH/8-1:0] wstrb1,
    input [AWIDTH-1:0] raddr1,
    output [WIDTH-1:0] rdata1,
    input [AWIDTH-1:0] raddr2,
    output [WIDTH-1:0] rdata2
);

    reg [WIDTH-1:0] mem [DEPTH-1:0];

    integer i;
    always @(posedge clk) begin
        for (i=0; i<WIDTH/8; i=i+1) if (wen1 && wstrb1[i]) mem[waddr1][i*8+:8] <= wdata1[i*8+:8];
    end

    assign rdata1 = mem[raddr1];
    assign rdata2 = mem[raddr2];

endmodule
