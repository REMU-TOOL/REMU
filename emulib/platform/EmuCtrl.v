`timescale 1ns / 1ps

`include "axi.vh"

module EmuCtrl #(
    parameter       TRIG_COUNT      = 1, // max = 128
    parameter       RESET_COUNT     = 1, // max = 128
    parameter       FF_COUNT        = 0,
    parameter       MEM_COUNT       = 0,

    parameter       __TRIG_COUNT    = TRIG_COUNT > 0 ? TRIG_COUNT : 1,
    parameter       __RESET_COUNT   = RESET_COUNT > 0 ? RESET_COUNT : 1,
    parameter       __CKPT_FF_CNT   = (FF_COUNT + 63) / 64,
    parameter       __CKPT_MEM_CNT  = (MEM_COUNT + 63) / 64,
    parameter       __CKPT_CNT      = __CKPT_FF_CNT + __CKPT_MEM_CNT,
    parameter       __CKPT_PAGES    = (__CKPT_CNT * 8 + 'hfff) / 'h1000
)(

    input  wire         host_clk,
    input  wire         host_rst,

    input  wire         tick,
    input  wire         model_busy,

    output reg          run_mode,
    output reg          scan_mode,

    output wire         ff_se,
    output wire         ff_di,
    input  wire         ff_do,
    output wire         ram_sr,
    output wire         ram_se,
    output wire         ram_sd,
    output wire         ram_di,
    input  wire         ram_do,

    output wire         source_wen,
    output wire [ 7:0]  source_waddr,
    output wire [31:0]  source_wdata,
    output wire         source_ren,
    output wire [ 7:0]  source_raddr,
    input  wire [31:0]  source_rdata,

    output wire         sink_wen,
    output wire [ 7:0]  sink_waddr,
    output wire [31:0]  sink_wdata,
    output wire         sink_ren,
    output wire [ 7:0]  sink_raddr,
    input  wire [31:0]  sink_rdata,

    input  wire [__TRIG_COUNT-1:0]    trig,
    output reg  [__RESET_COUNT-1:0]   rst,

    (* __emu_axi_name = "s_axilite" *)
    (* __emu_axi_type = "axi4" *)
    (* __emu_axi_addr_space = "ctrl" *)
    (* __emu_axi_addr_pages = 1 *)
    `AXI4LITE_SLAVE_IF  (s_axilite, 12, 32),

    (* __emu_axi_name = "scan_dma_axi" *)
    (* __emu_axi_type = "axi4" *)
    (* __emu_axi_addr_space = "mem" *)
    (* __emu_axi_addr_pages = __CKPT_PAGES *)
    `AXI4_MASTER_IF_NO_ID           (scan_dma_axi, 32, 64)

);

    genvar i;

    wire         ctrl_wen;
    wire [ 9:0]  ctrl_waddr;
    wire [31:0]  ctrl_wdata;
    wire         ctrl_ren;
    wire [ 9:0]  ctrl_raddr;
    reg  [31:0]  ctrl_rdata;

    localparam  MODE_CTRL   = 10'b0000_0000_00; // 0x000
    localparam  STEP_CNT    = 10'b0000_0000_01; // 0x004
    localparam  TICK_CNT_LO = 10'b0000_0000_10; // 0x008
    localparam  TICK_CNT_HI = 10'b0000_0000_11; // 0x00c
    localparam  SCAN_CTRL   = 10'b0000_0001_00; // 0x010
    localparam  TRIG_STAT   = 10'b0001_0000_??; // 0x100 - 0x10c
    localparam  TRIG_EN     = 10'b0001_0001_??; // 0x110 - 0x11c
    localparam  RESET_CTRL  = 10'b0001_0010_??; // 0x120 - 0x12c
    localparam  SOURCE_CTRL = 10'b10??_????_??; // 0x800 - 0xbfc
    localparam  SINK_CTRL   = 10'b11??_????_??; // 0xc00 - 0xffc

    reg w_mode_ctrl;
    reg w_step_cnt;
    reg w_tick_cnt_lo;
    reg w_tick_cnt_hi;
    reg w_scan_ctrl;
    reg w_trig_stat;
    reg w_trig_en;
    reg w_reset_ctrl;
    reg w_source_ctrl;
    reg w_sink_ctrl;

    always @* begin
        w_mode_ctrl     = 1'b0;
        w_step_cnt      = 1'b0;
        w_tick_cnt_lo   = 1'b0;
        w_tick_cnt_hi   = 1'b0;
        w_scan_ctrl     = 1'b0;
        w_trig_stat     = 1'b0;
        w_trig_en       = 1'b0;
        w_reset_ctrl    = 1'b0;
        w_source_ctrl   = 1'b0;
        w_sink_ctrl     = 1'b0;
        casez (ctrl_waddr)
            MODE_CTRL   :   w_mode_ctrl     = 1'b1;
            STEP_CNT    :   w_step_cnt      = 1'b1;
            TICK_CNT_LO :   w_tick_cnt_lo   = 1'b1;
            TICK_CNT_HI :   w_tick_cnt_hi   = 1'b1;
            SCAN_CTRL   :   w_scan_ctrl     = 1'b1;
            TRIG_STAT   :   w_trig_stat     = 1'b1;
            TRIG_EN     :   w_trig_en       = 1'b1;
            RESET_CTRL  :   w_reset_ctrl    = 1'b1;
            SOURCE_CTRL :   w_source_ctrl   = 1'b1;
            SINK_CTRL   :   w_sink_ctrl     = 1'b1;
        endcase
    end

    //////////////////// Register Definitions Begin ////////////////////

    // MODE_CTRL
    //      [0]     -> RUN_MODE [RW]
    //      [1]     -> SCAN_MODE [RW]
    //      [2]     -> PAUSE_BUSY [RO]
    //      [3]     -> MODEL_BUSY [RO]

    reg pause_busy;

    wire trig_active;
    wire step_finishing;
    wire run_to_pause = (pause_busy || trig_active || step_finishing) && tick;

    always @(posedge host_clk) begin
        if (host_rst) begin
            run_mode <= 1'b0;
            pause_busy <= 1'b0;
        end
        else if (run_to_pause) begin
            run_mode <= 1'b0;
            pause_busy <= 1'b0;
        end
        else if (ctrl_wen && w_mode_ctrl) begin
            if (ctrl_wdata[0]) begin
                run_mode <= 1'b1;
                pause_busy <= 1'b0;
            end
            else begin
                pause_busy <= 1'b1;
            end
        end
    end

    always @(posedge host_clk) begin
        if (host_rst) begin
            scan_mode <= 1'b0;
        end
        else if (ctrl_wen && w_mode_ctrl) begin
            scan_mode <= ctrl_wdata[1];
        end
    end

    wire [31:0] mode_ctrl = {28'd0, model_busy, pause_busy, scan_mode, run_mode};

    // STEP_CNT
    //      [31:0]  -> STEP [RW]

    reg [31:0] step_cnt;

    always @(posedge host_clk) begin
        if (host_rst) begin
            step_cnt <= 32'd0;
        end
        else if (run_mode && tick) begin
            step_cnt <= step_cnt == 32'd0 ? 32'd0 : step_cnt - 32'd1;
        end
        else if (!run_mode && ctrl_wen && w_step_cnt) begin
            step_cnt <= ctrl_wdata;
        end
    end

    assign step_finishing = step_cnt == 32'd1;

    // TICK_CNT_LO
    //      [31:0]  -> COUNT_LO [RW]
    // TICK_CNT_HI
    //      [31:0]  -> COUNT_HI [RW]

    reg [63:0] tick_cnt;

    always @(posedge host_clk) begin
        if (host_rst) begin
            tick_cnt <= 64'd0;
        end
        else if (run_mode && tick) begin
            tick_cnt <= tick_cnt + 64'd1;
        end
        else begin
            if (!run_mode && ctrl_wen && w_tick_cnt_lo) begin
                tick_cnt[31:0] <= ctrl_wdata;
            end
            if (!run_mode && ctrl_wen && w_tick_cnt_hi) begin
                tick_cnt[63:32] <= ctrl_wdata;
            end
        end
    end

    // SCAN_CTRL
    //      [0]     -> RUNNING [RO] / START [WO]
    //      [1]     -> DIRECTION [WO]

    wire dma_start, dma_running;
    reg dma_direction;

    always @(posedge host_clk) begin
        if (host_rst) begin
            dma_direction <= 1'b0;
        end
        else if (ctrl_wen && w_scan_ctrl && !dma_running) begin
            dma_direction <= ctrl_wdata[1];
        end
    end

    assign dma_start = ctrl_wen && w_scan_ctrl && ctrl_wdata[0];

    wire [31:0] scan_ctrl = {30'd0, dma_direction, dma_running};

    // TRIG_STAT [RO]

    // Register space:
    //      MSB                  LSB
    // 0x0: trig_stat[31]   ...  trig_stat[0]
    // 0x4: trig_stat[63]   ...  trig_stat[32]
    // 0x8: trig_stat[95]   ...  trig_stat[64]
    // 0xc: trig_stat[127]  ...  trig_stat[96]

    reg [__TRIG_COUNT-1:0] trig_stat;

    always @(posedge host_clk) begin
        if (host_rst) begin
            trig_stat <= {__TRIG_COUNT{1'b0}};
        end
        else if (run_mode) begin
            trig_stat <= trig;
        end
    end

    wire trig_stat_rdata = trig_stat[ctrl_raddr[1:0]*32+:32];

    // TRIG_EN [RW]

    // Register space:
    //      MSB                LSB
    // 0x0: trig_en[31]   ...  trig_en[0]
    // 0x4: trig_en[63]   ...  trig_en[32]
    // 0x8: trig_en[95]   ...  trig_en[64]
    // 0xc: trig_en[127]  ...  trig_en[96]

    reg [__TRIG_COUNT-1:0] trig_en;

    for (i=0; i<__TRIG_COUNT; i=i+1) begin
        always @(posedge host_clk) begin
            if (host_rst) begin
                trig_en[i] <= 1'b0;
            end
            else if (ctrl_wen && w_trig_en && ctrl_waddr[1:0] == i/32) begin
                trig_en[i] <= ctrl_wdata[i%32];
            end
        end
    end

    wire trig_en_rdata = trig_en[ctrl_raddr[1:0]*32+:32];

    assign trig_active = |{trig_en & trig};

    // RESET_CTRL [RW]

    // Register space:
    //      MSB            LSB
    // 0x0: rst[31]   ...  rst[0]
    // 0x4: rst[63]   ...  rst[32]
    // 0x8: rst[95]   ...  rst[64]
    // 0xc: rst[127]  ...  rst[96]

    for (i=0; i<__RESET_COUNT; i=i+1) begin
        always @(posedge host_clk) begin
            if (host_rst) begin
                rst[i] <= 1'b0;
            end
            else if (ctrl_wen && w_reset_ctrl && ctrl_waddr[1:0] == i/32) begin
                rst[i] <= ctrl_wdata[i%32];
            end
        end
    end

    wire reset_ctrl_rdata = rst[ctrl_raddr[1:0]*32+:32];

    // SOURCE_CTRL
    // SINK_CTRL

    reg r_source_ctrl;
    reg r_sink_ctrl;

    always @* begin
        r_source_ctrl   = 1'b0;
        r_sink_ctrl     = 1'b0;
        casez (ctrl_raddr)
            SOURCE_CTRL :   r_source_ctrl   = 1'b1;
            SINK_CTRL   :   r_sink_ctrl     = 1'b1;
        endcase
    end

    assign source_wen   = ctrl_wen && w_source_ctrl;
    assign source_waddr = ctrl_waddr[7:0];
    assign source_wdata = ctrl_wdata;
    assign source_ren   = ctrl_ren && r_source_ctrl;
    assign source_raddr = ctrl_raddr[7:0];

    assign sink_wen     = ctrl_wen && w_sink_ctrl;
    assign sink_waddr   = ctrl_waddr[7:0];
    assign sink_wdata   = ctrl_wdata;
    assign sink_ren     = ctrl_ren && r_sink_ctrl;
    assign sink_raddr   = ctrl_raddr[7:0];

    //////////////////// Register Definitions End ////////////////////

    always @* begin
        ctrl_rdata = 32'd0;
        casez (ctrl_raddr)
            MODE_CTRL   :   ctrl_rdata = mode_ctrl;
            STEP_CNT    :   ctrl_rdata = step_cnt;
            TICK_CNT_LO :   ctrl_rdata = tick_cnt[31:0];
            TICK_CNT_HI :   ctrl_rdata = tick_cnt[63:32];
            SCAN_CTRL   :   ctrl_rdata = scan_ctrl;
            TRIG_STAT   :   ctrl_rdata = trig_stat_rdata;
            TRIG_EN     :   ctrl_rdata = trig_en_rdata;
            RESET_CTRL  :   ctrl_rdata = reset_ctrl_rdata;
            SOURCE_CTRL :   ctrl_rdata = source_rdata;
            SINK_CTRL   :   ctrl_rdata = sink_rdata;
        endcase
    end

    AXILiteToCtrl bridge (
        .clk        (host_clk),
        .rst        (host_rst),
        .ctrl_wen   (ctrl_wen),
        .ctrl_waddr (ctrl_waddr),
        .ctrl_wdata (ctrl_wdata),
        .ctrl_ren   (ctrl_ren),
        .ctrl_raddr (ctrl_raddr),
        .ctrl_rdata (ctrl_rdata),
        `AXI4LITE_CONNECT(s_axilite, s_axilite)
    );

    ScanchainCtrl #(
        .FF_COUNT   (FF_COUNT),
        .MEM_COUNT  (MEM_COUNT),
        .__CKPT_CNT (__CKPT_CNT)
    ) scanchain (
        .host_clk       (host_clk),
        .host_rst       (host_rst),
        .ff_se          (ff_se),
        .ff_di          (ff_di),
        .ff_do          (ff_do),
        .ram_sr         (ram_sr),
        .ram_se         (ram_se),
        .ram_sd         (ram_sd),
        .ram_di         (ram_di),
        .ram_do         (ram_do),
        .dma_start      (dma_start),
        .dma_running    (dma_running),
        .dma_direction  (dma_direction),
        `AXI4_CONNECT_NO_ID     (dma_axi, scan_dma_axi)
    );

endmodule
