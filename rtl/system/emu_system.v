`include "loader.vh"
`include "emu_csr.vh"

`timescale 1ns / 1ps

module emu_system(
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
    output  [ 1:0]  s_axilite_bresp
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

    assign s_axilite_awready    = !reg_write_addr_valid && !reg_write_resp_valid;
    assign s_axilite_wready     = !reg_write_data_valid;
    assign s_axilite_bvalid     = reg_write_resp_valid;
    assign s_axilite_bresp      = reg_write_error ? 2'b10 : 2'b00;

    wire step_trig;
    wire [31:0] emu_dut_trig;

    wire trigger = |{step_trig, emu_dut_trig};

    // EMU_STAT
    //      [0]     -> HALT
    //      [1]     -> DUT_RESET
    //      [31]    -> STEP_TRIG [RO]

    reg emu_halt, emu_dut_reset, emu_step_trig;
    wire [31:0] emu_stat, emu_ctrl;
    assign emu_stat[31]     = emu_step_trig;
    assign emu_stat[30:2]   = 29'd0;
    assign emu_stat[1]      = emu_dut_reset;
    assign emu_stat[0]      = emu_halt;
    assign emu_ctrl         = 32'd0;

    always @(posedge clk) begin
        if (rst) begin
            emu_halt            <= 1'b1;
            emu_dut_reset       <= 1'b1;
            emu_step_trig       <= 1'b0;
        end
        else if (trigger) begin
            emu_halt            <= 1'b1;
            emu_step_trig       <= step_trig;
        end
        else begin
            if (reg_do_write && reg_write_addr == `EMU_STAT) begin
                emu_halt            <= reg_write_data[0];
                emu_dut_reset       <= reg_write_data[1];
            end
        end
    end

    // EMU_TRIG_STAT
    reg [31:0] emu_trig_stat;

    always @(posedge clk) begin
        if (rst) begin
            emu_trig_stat       <= 32'd0;
        end
        else if (trigger) begin
            emu_trig_stat       <= emu_dut_trig;
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

    assign step_trig = emu_step != 32'd0 && emu_step_next == 32'd0;

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

    // EMU_CKPT_SIZE
    wire [31:0] emu_ckpt_size = 8 * (`CHAIN_FF_WORDS + `CHAIN_MEM_WORDS);

    // EMU_DMA_ADDR_LO
    // EMU_DMA_ADDR_HI
    // EMU_DMA_STAT
    //      [0]     -> RUNNING [RO]
    //      [7:4]   -> ERROR [RO]
    // EMU_DMA_CTRL
    //      [0]     -> START [WARL]
    //      [1]     -> DIRECTION [WARL]

    reg [63:0] emu_dma_addr;
    reg emu_dma_start, emu_dma_running, emu_dma_direction;
    reg [3:0] emu_dma_error;
    wire [31:0] emu_dma_stat, emu_dma_ctrl;
    assign emu_dma_stat[31:8]   = 24'd0;
    assign emu_dma_stat[7:4]    = emu_dma_error;
    assign emu_dma_stat[3:1]    = 3'd0;
    assign emu_dma_stat[0]      = emu_dma_running;
    assign emu_dma_ctrl[31:2]   = 30'd0;
    assign emu_dma_ctrl[1]      = emu_dma_direction;
    assign emu_dma_ctrl[0]      = emu_dma_start;

    wire [27:0] emu_dma_len     = emu_ckpt_size[27:0]; // TODO: handle overflow

    wire read_desc_fire         = s_axis_read_desc_valid && s_axis_read_desc_ready;
    wire write_desc_fire        = s_axis_write_desc_valid && s_axis_write_desc_ready;

    always @(posedge clk) begin
        if (rst) begin
            emu_dma_addr            <= 64'd0;
            emu_dma_start           <= 1'b0;
            emu_dma_running         <= 1'b0;
            emu_dma_direction       <= 1'b0;
            emu_dma_error           <= 4'd0;
        end
        else begin
            if (read_desc_fire || write_desc_fire) begin
                emu_dma_start           <= 1'b0;
            end
            if (m_axis_read_desc_status_valid) begin
                emu_dma_running         <= 1'b0;
                emu_dma_error           <= m_axis_read_desc_status_error;
            end
            if (m_axis_write_desc_status_valid) begin
                emu_dma_running         <= 1'b0;
                emu_dma_error           <= m_axis_write_desc_status_error;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_ADDR_LO) begin
                emu_dma_addr[31:0]      <= reg_write_data;
            end
            if (reg_do_write && reg_write_addr == `EMU_DMA_ADDR_HI) begin
                emu_dma_addr[63:32]     <= reg_write_data;
            end
            if (!emu_dma_running && reg_do_write && reg_write_addr == `EMU_DMA_CTRL) begin
                emu_dma_start           <= reg_write_data[0];
                emu_dma_running         <= reg_write_data[0];
                emu_dma_direction       <= reg_write_data[1];
            end
        end
    end

    assign s_axis_read_desc_valid   = emu_dma_start && emu_dma_direction;
    assign s_axis_write_desc_valid  = emu_dma_start && !emu_dma_direction;

    // CSR read logic

    reg [11:0] reg_read_addr;
    reg [31:0] reg_read_data, reg_read_data_wire;
    reg reg_read_addr_valid, reg_read_data_valid;
    wire reg_do_read = reg_read_addr_valid && !reg_read_data_valid;

    always @* begin
        case (reg_read_addr)
            `EMU_STAT:              reg_read_data_wire = emu_stat;
            `EMU_TRIG_STAT:         reg_read_data_wire = emu_trig_stat;
            `EMU_CYCLE_LO:          reg_read_data_wire = emu_cycle[31:0];
            `EMU_CYCLE_HI:          reg_read_data_wire = emu_cycle[63:32];
            `EMU_STEP:              reg_read_data_wire = emu_step;
            `EMU_CKPT_SIZE:         reg_read_data_wire = emu_ckpt_size;
            `EMU_DMA_ADDR_LO:       reg_read_data_wire = emu_dma_addr[31:0];
            `EMU_DMA_ADDR_HI:       reg_read_data_wire = emu_dma_addr[63:32];
            `EMU_DMA_STAT:          reg_read_data_wire = emu_dma_stat;
            `EMU_DMA_CTRL:          reg_read_data_wire = emu_dma_ctrl;
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
        .AXIS_USER_ENABLE               (0),
        .LEN_WIDTH                      (28)
    )
    u_dma(
        .clk                            (clk),
        .rst                            (rst),

        /*
        * AXI read descriptor input
        */
        .s_axis_read_desc_addr          (emu_dma_addr),
        .s_axis_read_desc_len           (emu_dma_len),
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
        .s_axis_write_desc_addr         (emu_dma_addr),
        .s_axis_write_desc_len          (emu_dma_len),
        .s_axis_write_desc_tag          (8'd0),
        .s_axis_write_desc_valid        (s_axis_write_desc_valid),
        .s_axis_write_desc_ready        (s_axis_write_desc_ready),

        /*
        * AXI write descriptor status output
        */
        .m_axis_write_desc_status_len   (),
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
        .read_enable                    (emu_dma_running && emu_dma_direction),
        .write_enable                   (emu_dma_running && !emu_dma_direction),
        .write_abort                    (1'b0)
    );

    // DUT & scan logic

    wire dut_clk, dut_clk_en;
    clock_gate dut_clk_gate(
        .clk(clk),
        .en(dut_clk_en),
        .gclk(dut_clk)
    );

    // operation sequence
    // (<L> = last data, N = CHAIN_FF_WORDS or CHAIN_MEM_WORDS)
    // scan-out:
    // FF SCAN      0   1   1   ..  1   0   0   0   0   ..  0   0
    // FF START     1   0   0   ..  0   0   0   0   0   ..  0   0
    // FF RUNNING   0   1   1   ..  1   0   0   0   0   ..  0   0
    // FF LAST      0   0   0   ..  1   0   0   0   0   ..  0   0
    // FF DATA      x  <0> <1>  .. <L>  x   x   x   x   ..  x   x
    // FF CNT       0   1   2   ..  N   0   0   0   0   ..  0   0
    // RAM SCAN     0   0   0   ..  0   1   1   1   1   ..  1   0
    // RAM START    0   0   0   ..  0   0   1   0   0   ..  0   0
    // RAM RUNNING  0   0   0   ..  0   0   0   1   1   ..  1   0
    // RAM LAST     0   0   0   ..  0   0   0   0   0   ..  1   0
    // RAM DATA     x   x   x   ..  x   x   x  <0> <1>  .. <L>  x
    // RAM CNT      0   0   0   ..  0   0   0   1   2   ..  N   0
    // scan-in:
    // FF SCAN      0   1   1   ..  1   0   0   ..  0   0
    // FF START     1   0   0   ..  0   0   0   ..  0   0
    // FF RUNNING   0   1   1   ..  1   0   0   ..  0   0
    // FF LAST      0   0   0   ..  1   0   0   ..  0   0
    // FF DATA      x  <0> <1>  .. <L>  x   x   ..  x   x
    // FF CNT       0   1   2   ..  N   0   0   ..  0   0
    // RAM SCAN     0   0   0   ..  0   1   1   ..  1   0
    // RAM START    0   0   0   ..  1   0   0   ..  0   0
    // RAM RUNNING  0   0   0   ..  0   1   1   ..  1   0
    // RAM LAST     0   0   0   ..  0   0   0   ..  1   0
    // RAM DATA     x   x   x   ..  x  <0> <1>  .. <L>  x
    // RAM CNT      0   0   0   ..  0   1   2   ..  N   0

    // ff_scan_running = FF SCAN = FF RUNNING
    // ram_scan_running = RAM RUNNING
    // ram_scan_sig = RAM SCAN
    reg ff_scan_running, ram_scan_running, ram_scan_sig;
    wire [63:0] ff_sdi, ff_sdo, ram_sdi, ram_sdo;

    localparam CNT_BITS_FF  = $clog2(`CHAIN_FF_WORDS + 1);
    localparam CNT_BITS_RAM = $clog2(`CHAIN_MEM_WORDS + 1);

    reg [CNT_BITS_FF-1:0]   ff_scan_cnt;
    reg [CNT_BITS_RAM-1:0]  ram_scan_cnt;
    
    wire scan_running   = ff_scan_running || ram_scan_running;

    wire ff_scan_start  = read_desc_fire || write_desc_fire;
    wire ff_scan_last   = (ff_scan_start || ff_scan_running) && ff_scan_cnt == `CHAIN_FF_WORDS;

    reg [1:0] ram_scan_wait;
    always @(posedge dut_clk) begin
        if (rst)
            ram_scan_wait <= 2'd0;
        else
            ram_scan_wait <= {ram_scan_wait[0], ff_scan_last};
    end

    // wait 2 cycles in scan-out mode
    wire ram_scan_start = emu_dma_direction ? ff_scan_last : ram_scan_wait[1];
    wire ram_scan_last  = (ram_scan_start || ram_scan_running) && ram_scan_cnt == `CHAIN_MEM_WORDS;

    always @(posedge dut_clk) begin
        if (rst)
            ff_scan_running <= 1'b0;
        else if (ff_scan_last)
            ff_scan_running <= 1'b0;
        else if (ff_scan_start)
            ff_scan_running <= 1'b1;
    end

    always @(posedge dut_clk) begin
        if (rst)
            ram_scan_running <= 1'b0;
        else if (ram_scan_last)
            ram_scan_running <= 1'b0;
        else if (ram_scan_start)
            ram_scan_running <= 1'b1;
    end

    always @(posedge dut_clk) begin
        if (rst)
            ram_scan_sig <= 1'b0;
        else if (ram_scan_last)
            ram_scan_sig <= 1'b0;
        else if (ff_scan_last)
            ram_scan_sig <= 1'b1;
    end

    always @(posedge dut_clk) begin
        if (rst)
            ff_scan_cnt <= 0;
        else if (ff_scan_last)
            ff_scan_cnt <= 0;
        else if (ff_scan_start || ff_scan_running)
            ff_scan_cnt <= ff_scan_cnt + 1;
    end

    always @(posedge dut_clk) begin
        if (rst)
            ram_scan_cnt <= 0;
        else if (ram_scan_last)
            ram_scan_cnt <= 0;
        else if (ram_scan_start || ram_scan_running)
            ram_scan_cnt <= ram_scan_cnt + 1;
    end

    if (`CHAIN_FF_WORDS == 0)
        assign ff_sdi = 64'd0; // to avoid combinational logic loop
    else
        assign ff_sdi = emu_dma_direction ? m_axis_read_data_tdata : ff_sdo;
    assign ram_sdi = m_axis_read_data_tdata;

    EMU_DUT emu_dut(
        .\$EMU$CLK          (dut_clk),
        .\$EMU$HALT         (emu_halt),
        .\$EMU$DUT$RESET    (emu_dut_reset),
        .\$EMU$DUT$TRIG     (emu_dut_trig),
        .\$EMU$FF$SCAN      (ff_scan_running),
        .\$EMU$FF$SDI       (ff_sdi),
        .\$EMU$FF$SDO       (ff_sdo),
        .\$EMU$RAM$SCAN     (ram_scan_sig),
        .\$EMU$RAM$DIR      (emu_dma_direction),
        .\$EMU$RAM$SDI      (ram_sdi),
        .\$EMU$RAM$SDO      (ram_sdo)
    );

    assign m_axis_read_data_tready  = emu_dma_direction && scan_running;
    assign s_axis_write_data_tvalid = !emu_dma_direction && scan_running;
    assign s_axis_write_data_tlast  = ram_scan_last;
    assign s_axis_write_data_tdata  = {64{ff_scan_running}} & ff_sdo | {64{ram_scan_running}} & ram_sdo;

    wire scan_stall = scan_running && (emu_dma_direction ? !m_axis_read_data_tvalid : !s_axis_write_data_tready);
    assign dut_clk_en = !scan_stall;

endmodule
