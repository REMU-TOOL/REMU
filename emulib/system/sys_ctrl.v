`timescale 1ns / 1ps

`include "axi.vh"

module EmuSysCtrl #(
    parameter   TRIG_COUNT      = 1, // max = 128
    parameter   __TRIG_COUNT    = TRIG_COUNT > 0 ? TRIG_COUNT : 1
)(
    input  wire         host_clk,
    input  wire         host_rst,

    input  wire         tick,
    output reg [63:0] 	tick_cnt,
    input  wire         model_busy,
    input  wire         trace_full,

    output reg          run_mode,
    input  wire         pause_pending,
    output reg          scan_mode,

    input  wire [__TRIG_COUNT-1:0]    trig,

    input  wire         ctrl_wen,
    input  wire [11:0]  ctrl_waddr,
    input  wire [31:0]  ctrl_wdata,
    input  wire         ctrl_ren,
    input  wire [11:0]  ctrl_raddr,
    output reg  [31:0]  ctrl_rdata,

    output wire         dma_start,
    output reg          dma_direction,
    input  wire         dma_running,

    input  wire         uart_tx_valid,
    output wire         uart_tx_ready,
    input  wire [7:0]   uart_tx_data
);

    genvar i;

    localparam  MODE_CTRL   = 10'b0000_0000_00; // 0x000
    localparam  STEP_CNT    = 10'b0000_0000_01; // 0x004
    localparam  TICK_CNT_LO = 10'b0000_0000_10; // 0x008
    localparam  TICK_CNT_HI = 10'b0000_0000_11; // 0x00c
    localparam  SCAN_CTRL   = 10'b0000_0001_00; // 0x010
    localparam  UART_DATA   = 10'b0000_1000_00; // 0x080
    localparam  TRIG_STAT   = 10'b0001_0000_??; // 0x100 - 0x10c
    localparam  TRIG_EN     = 10'b0001_0001_??; // 0x110 - 0x11c

    reg w_mode_ctrl;
    reg w_step_cnt;
    reg w_tick_cnt_lo;
    reg w_tick_cnt_hi;
    reg w_scan_ctrl;
    reg w_trig_stat;
    reg w_trig_en;

    always @* begin
        w_mode_ctrl     = 1'b0;
        w_step_cnt      = 1'b0;
        w_tick_cnt_lo   = 1'b0;
        w_tick_cnt_hi   = 1'b0;
        w_scan_ctrl     = 1'b0;
        w_trig_stat     = 1'b0;
        w_trig_en       = 1'b0;
        casez (ctrl_waddr[11:2])
            MODE_CTRL   :   w_mode_ctrl     = 1'b1;
            STEP_CNT    :   w_step_cnt      = 1'b1;
            TICK_CNT_LO :   w_tick_cnt_lo   = 1'b1;
            TICK_CNT_HI :   w_tick_cnt_hi   = 1'b1;
            SCAN_CTRL   :   w_scan_ctrl     = 1'b1;
            TRIG_STAT   :   w_trig_stat     = 1'b1;
            TRIG_EN     :   w_trig_en       = 1'b1;
        endcase
    end

    reg r_uart_data;

    always @* begin
        r_uart_data = 1'b0;
        casez (ctrl_raddr[11:2])
            UART_DATA:      r_uart_data     = 1'b1;
        endcase
    end

    //////////////////// Register Definitions Begin ////////////////////

    // MODE_CTRL
    //      [0]     -> RUN_MODE [RW]
    //      [1]     -> SCAN_MODE [RW]
    //      [2]     -> PAUSE_BUSY [RO]
    //      [3]     -> MODEL_BUSY [RO]
    //      [4]     -> PAUSE_PENDING [RO]

    reg pause_busy;

    wire trig_active;
    wire step_finishing;
    wire run_to_pause = (pause_busy || trig_active || step_finishing || trace_full) && tick;

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
            else if (run_mode) begin
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

    wire [31:0] mode_ctrl = {27'd0, pause_pending, model_busy, pause_busy, scan_mode, run_mode};

    // STEP_CNT
    //      [31:0]  -> STEP [RW]

    reg [31:0] step_cnt;

    always @(posedge host_clk) begin
        if (host_rst) begin
            step_cnt <= 32'd0;
        end
        else if ((run_mode || pause_pending) && tick) begin
            step_cnt <= step_cnt == 32'd0 ? 32'd0 : step_cnt - 32'd1;
        end
        else if (!(run_mode || pause_pending) && ctrl_wen && w_step_cnt) begin
            step_cnt <= ctrl_wdata;
        end
    end

    assign step_finishing = step_cnt == 32'd1;

    // TICK_CNT_LO
    //      [31:0]  -> COUNT_LO [RW]
    // TICK_CNT_HI
    //      [31:0]  -> COUNT_HI [RW]


    always @(posedge host_clk) begin
        if (host_rst) begin
            tick_cnt <= 64'd0;
        end
        else if ((run_mode || pause_pending) && tick) begin
            tick_cnt <= tick_cnt + 64'd1;
        end
        else begin
            if (!(run_mode || pause_pending) && ctrl_wen && w_tick_cnt_lo) begin
                tick_cnt[31:0] <= ctrl_wdata;
            end
            if (!(run_mode || pause_pending) && ctrl_wen && w_tick_cnt_hi) begin
                tick_cnt[63:32] <= ctrl_wdata;
            end
        end
    end

    // SCAN_CTRL
    //      [0]     -> RUNNING [RO] / START [WO]
    //      [1]     -> DIRECTION [WO]

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

    // UART_DATA [RO]
    //      [7:0]   -> tx_data
    //      [31]    -> tx_valid

    wire [31:0] uart_data = {uart_tx_valid, 23'd0, uart_tx_data};
    assign uart_tx_ready = ctrl_ren && r_uart_data;

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
        else if (run_mode || pause_pending) begin
            trig_stat <= trig;
        end
    end

    wire [127:0] trig_stat_padded = {{128-__TRIG_COUNT{1'b0}}, trig_stat};
    wire [31:0] trig_stat_rdata = trig_stat_padded[ctrl_raddr[3:2]*32+:32];

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
            else if (ctrl_wen && w_trig_en && ctrl_waddr[3:2] == i/32) begin
                trig_en[i] <= ctrl_wdata[i%32];
            end
        end
    end

    wire [127:0] trig_en_padded = {{128-__TRIG_COUNT{1'b0}}, trig_en};
    wire [31:0] trig_en_rdata = trig_en_padded[ctrl_raddr[3:2]*32+:32];

    assign trig_active = |{trig_en & trig};

    //////////////////// Register Definitions End ////////////////////

    always @* begin
        ctrl_rdata = 32'd0;
        casez (ctrl_raddr[11:2])
            MODE_CTRL   :   ctrl_rdata = mode_ctrl;
            STEP_CNT    :   ctrl_rdata = step_cnt;
            TICK_CNT_LO :   ctrl_rdata = tick_cnt[31:0];
            TICK_CNT_HI :   ctrl_rdata = tick_cnt[63:32];
            SCAN_CTRL   :   ctrl_rdata = scan_ctrl;
            UART_DATA   :   ctrl_rdata = uart_data;
            TRIG_STAT   :   ctrl_rdata = trig_stat_rdata;
            TRIG_EN     :   ctrl_rdata = trig_en_rdata;
        endcase
    end

endmodule
