`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"

module EmuCtrl #(
    parameter       TRIG_COUNT      = 1, // max = 128
    parameter       RESET_COUNT     = 1, // max = 128

    parameter       FF_COUNT        = 0,
    parameter       MEM_COUNT       = 0,
    parameter       FF_WIDTH        = 64,
    parameter       MEM_WIDTH       = 64
)(

    input  wire         host_clk,
    input  wire         host_rst,

    input  wire         tick,

    output reg          run_mode,
    output reg          scan_mode,

    output wire         ff_se,
    output wire [63:0]  ff_di,
    input  wire [63:0]  ff_do,
    output wire         ram_sr,
    output wire         ram_se,
    output wire         ram_sd,
    output wire [63:0]  ram_di,
    input  wire [63:0]  ram_do,

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

    input  wire [TRIG_COUNT-1:0]    trig,
    output reg  [TRIG_COUNT-1:0]    rst

);

    genvar i;

    wire         ctrl_wen;
    wire [ 9:0]  ctrl_waddr;
    wire [31:0]  ctrl_wdata;
    wire         ctrl_ren;
    wire [ 9:0]  ctrl_raddr;
    reg  [31:0]  ctrl_rdata;

    localparam  RUN_CTRL    = 10'b0000_0000_00; // 0x000
    localparam  TICK_STEP   = 10'b0000_0000_01; // 0x004
    localparam  TICK_CNT_LO = 10'b0000_0000_10; // 0x008
    localparam  TICK_CNT_HI = 10'b0000_0000_11; // 0x00c
    localparam  SCAN_CTRL   = 10'b0000_0001_00; // 0x010
    localparam  TRIG_STAT   = 10'b0001_0000_??; // 0x100 - 0x10c
    localparam  TRIG_EN     = 10'b0001_0001_??; // 0x110 - 0x11c
    localparam  RESET_CTRL  = 10'b0001_0010_??; // 0x120 - 0x12c
    localparam  SOURCE_CTRL = 10'b10??_????_??; // 0x800 - 0xbfc
    localparam  SINK_CTRL   = 10'b11??_????_??; // 0xc00 - 0xffc

    reg w_run_ctrl;
    reg w_tick_step;
    reg w_tick_cnt_lo;
    reg w_tick_cnt_hi;
    reg w_scan_ctrl;
    reg w_trig_stat;
    reg w_trig_en;
    reg w_reset_ctrl;
    reg w_source_ctrl;
    reg w_sink_ctrl;

    always @* begin
        w_run_ctrl      = 1'b0;
        w_tick_step     = 1'b0;
        w_tick_cnt_lo   = 1'b0;
        w_tick_cnt_hi   = 1'b0;
        w_scan_ctrl     = 1'b0;
        w_trig_stat     = 1'b0;
        w_trig_en       = 1'b0;
        w_reset_ctrl    = 1'b0;
        w_source_ctrl   = 1'b0;
        w_sink_ctrl     = 1'b0;
        casez (ctrl_waddr)
            RUN_CTRL    :   w_run_ctrl      = 1'b1;
            TICK_STEP   :   w_tick_step     = 1'b1;
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

    // RUN_CTRL
    //      [0]     -> RUN_MODE [RO] PAUSE_RESUME [WO]
    //      [1]     -> SCAN_MODE [RW]

    reg pause_resume;

    always @(posedge host_clk) begin
        if (host_rst) begin
            pause_resume <= 1'b0;
        end
        else if (ctrl_wen && w_run_ctrl) begin
            pause_resume <= ctrl_wdata[0];
        end
    end

    wire trig_active;
    wire step_finishing;
    wire pause_req = (!pause_resume || trig_active || step_finishing) && tick;
    wire resume_req = pause_resume;

    always @(posedge host_clk) begin
        if (host_rst) begin
            run_mode <= 1'b0;
        end
        else if (run_mode) begin
            run_mode <= run_mode ? !pause_req : resume_req;
        end
    end

    always @(posedge host_clk) begin
        if (host_rst) begin
            scan_mode <= 1'b0;
        end
        else if (ctrl_wen && w_run_ctrl) begin
            scan_mode <= ctrl_wdata[1];
        end
    end

    // TICK_STEP
    //      [31:0]  -> STEP [RW]

    reg tick_step;

    always @(posedge host_clk) begin
        if (host_rst) begin
            tick_step <= 32'd0;
        end
        else if (tick) begin
            tick_step <= tick_step - 32'd1;
        end
        else if (!run_mode && ctrl_wen && w_tick_step) begin
            tick_step <= ctrl_wdata;
        end
    end

    assign step_finishing = tick_step == 32'd1;

    // TICK_CNT_LO
    //      [31:0]  -> COUNT_LO [RW]
    // TICK_CNT_HI
    //      [31:0]  -> COUNT_HI [RW]

    reg [63:0] tick_cnt;

    always @(posedge host_clk) begin
        if (host_rst) begin
            tick_cnt <= 64'd0;
        end
        else if (tick) begin
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

    wire [31:0] scan_ctrl = {31'd0, dma_running};

    // TRIG_STAT [RO]

    // Register space:
    //      MSB                  LSB
    // 0x0: trig_stat[31]   ...  trig_stat[0]
    // 0x4: trig_stat[63]   ...  trig_stat[32]
    // 0x8: trig_stat[95]   ...  trig_stat[64]
    // 0xc: trig_stat[127]  ...  trig_stat[96]

    reg [TRIG_COUNT-1:0] trig_stat;

    always @(posedge host_clk) begin
        if (host_rst) begin
            trig_stat <= {TRIG_COUNT{1'b0}};
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

    reg [TRIG_COUNT-1:0] trig_en;

    for (i=0; i<TRIG_COUNT; i=i+1) begin
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

    // RESET_CTRL [RW]

    // Register space:
    //      MSB            LSB
    // 0x0: rst[31]   ...  rst[0]
    // 0x4: rst[63]   ...  rst[32]
    // 0x8: rst[95]   ...  rst[64]
    // 0xc: rst[127]  ...  rst[96]

    for (i=0; i<RESET_COUNT; i=i+1) begin
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
        casez (ctrl_waddr)
            RUN_CTRL    :   ctrl_rdata = run_ctrl;
            TICK_STEP   :   ctrl_rdata = tick_step;
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
        .ctrl_rdata (ctrl_rdata)
    );

    ScanchainCtrl #(
        .FF_COUNT   (FF_COUNT),
        .MEM_COUNT  (MEM_COUNT),
        .FF_WIDTH   (FF_WIDTH),
        .MEM_WIDTH  (MEM_WIDTH)
    ) ctrl_sc (
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
        .dma_direction  (dma_direction)
    );

endmodule

`default_nettype wire
