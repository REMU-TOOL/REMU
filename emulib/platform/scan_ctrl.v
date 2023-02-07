`timescale 1ns / 1ps

`include "axi.vh"

module EmuScanCtrl #(
    parameter   FF_COUNT        = 0,
    parameter   MEM_COUNT       = 0,
    parameter   __CKPT_FF_CNT   = (FF_COUNT + 63) / 64,
    parameter   __CKPT_MEM_CNT  = (MEM_COUNT + 63) / 64,
    parameter   __CKPT_CNT      = __CKPT_FF_CNT + __CKPT_MEM_CNT
)(

    input  wire         host_clk,
    input  wire         host_rst,

    output wire         ff_se,
    output wire         ff_di,
    input  wire         ff_do,
    output wire         ram_sr,
    output wire         ram_se,
    output wire         ram_sd,
    output wire         ram_di,
    input  wire         ram_do,

    input  wire         dma_start,
    input  wire         dma_direction,
    output wire         dma_running,

    `AXI4_MASTER_IF_NO_ID           (dma_axi, 40, 64)

);

    // DMA for scan chain

    wire        s_read_addr_valid;
    wire        s_read_addr_ready;
    wire        s_read_count_valid;
    wire        s_read_count_ready;
    wire        m_read_data_valid;
    wire        m_read_data_ready;
    wire [63:0] m_read_data;
    wire        s_write_addr_valid;
    wire        s_write_addr_ready;
    wire        s_write_count_valid;
    wire        s_write_count_ready;
    wire        s_write_data_valid;
    wire        s_write_data_ready;
    wire [63:0] s_write_data;

    wire r_idle, w_idle;

    localparam COUNT_WIDTH = $clog2(__CKPT_CNT);
    localparam __COUNT_WIDTH = COUNT_WIDTH > 0 ? COUNT_WIDTH : 1;

    emulib_simple_dma #(
        .ADDR_WIDTH     (40),
        .DATA_WIDTH     (64),
        .COUNT_WIDTH    (__COUNT_WIDTH)
    )
    u_dma(

        .clk                    (host_clk),
        .rst                    (host_rst),

        .s_read_addr_valid      (s_read_addr_valid),
        .s_read_addr_ready      (s_read_addr_ready),
        .s_read_addr            (40'd0),

        .s_read_count_valid     (s_read_count_valid),
        .s_read_count_ready     (s_read_count_ready),
        .s_read_count           (__CKPT_CNT[__COUNT_WIDTH-1:0]),

        .m_read_data_valid      (m_read_data_valid),
        .m_read_data_ready      (m_read_data_ready),
        .m_read_data            (m_read_data),

        .s_write_addr_valid     (s_write_addr_valid),
        .s_write_addr_ready     (s_write_addr_ready),
        .s_write_addr           (40'd0),

        .s_write_count_valid    (s_write_count_valid),
        .s_write_count_ready    (s_write_count_ready),
        .s_write_count          (__CKPT_CNT[__COUNT_WIDTH-1:0]),

        .s_write_data_valid     (s_write_data_valid),
        .s_write_data_ready     (s_write_data_ready),
        .s_write_data           (s_write_data),

        `AXI4_CONNECT_NO_ID     (m_axi, dma_axi),

        .r_idle                 (r_idle),
        .w_idle                 (w_idle)

    );

    wire s2p_p2s_rst;
    wire p2s_valid, p2s_ready, p2s_data;
    wire s2p_valid, s2p_ready, s2p_data;

    emulib_serializer #(.DATA_WIDTH(64))
    p2s (
        .clk        (host_clk),
        .rst        (host_rst || s2p_p2s_rst),
        .i_valid    (m_read_data_valid),
        .i_data     (m_read_data),
        .i_ready    (m_read_data_ready),
        .o_valid    (p2s_valid),
        .o_data     (p2s_data),
        .o_ready    (p2s_ready)
    );

    emulib_deserializer #(.DATA_WIDTH(64))
    s2p (
        .clk        (host_clk),
        .rst        (host_rst || s2p_p2s_rst),
        .i_valid    (s2p_valid),
        .i_data     (s2p_data),
        .i_ready    (s2p_ready),
        .o_valid    (s_write_data_valid),
        .o_data     (s_write_data),
        .o_ready    (s_write_data_ready)
    );

    wire dma_addr_ready = dma_direction ? s_read_addr_ready : s_write_addr_ready;
    wire dma_count_ready = dma_direction ? s_read_count_ready : s_write_count_ready;
    wire dma_idle = dma_direction ? r_idle : w_idle;

    wire scan_valid = dma_direction ? p2s_valid : s2p_ready;

    // DUT & scan logic

    // operation sequence
    // (<L> = last data, N = FF_COUNT or MEM_COUNT)
    // scan-out:
    // FF SCAN      0   1   1   ..  1   0   0   0   0   ..  0   0
    // FF LAST      0   0   0   ..  1   0   0   0   0   ..  0   0
    // FF DATA      x  <0> <1>  ..<N-1> x   x   x   x   ..  x   x
    // FF CNT       x   0   1   .. N-1  x   x   x   x   ..  x   x
    // RAM SCAN     0   0   0   ..  0   1   1   1   1   ..  1   0
    // RAM LAST     0   0   0   ..  0   0   0   0   0   ..  1   0
    // RAM DATA     x   x   x   ..  x   x   x  <0> <1>  ..<N-1> x
    // RAM CNT      x   x   x   ..  x   x   x   0   1   .. N-1  x
    // scan-in:
    // FF SCAN      0   1   1   ..  1   0   0   ..  0   0   0
    // FF LAST      0   0   0   ..  1   0   0   ..  0   0   0
    // FF DATA      x  <0> <1>  ..<N-1> x   x   ..  x   x   x
    // FF CNT       x   0   1   .. N-1  x   x   ..  x   x   x
    // RAM SCAN     0   0   0   ..  0   1   1   ..  1   1   0
    // RAM LAST     0   0   0   ..  0   0   0   ..  1   0   0
    // RAM DATA     x   x   x   ..  x  <0> <1>  ..<N-1> x   x
    // RAM CNT      x   x   x   ..  x   0   1   .. N-1  x   x

    wire ff_last, ram_last;

    localparam [3:0]
        STATE_IDLE          = 4'd00,
        STATE_SEND_ADDR     = 4'd01,
        STATE_SEND_COUNT    = 4'd02,
        STATE_FF_RESET      = 4'd03,
        STATE_FF_SCAN       = 4'd04,
        STATE_FF_S2P_PAD    = 4'd05,
        STATE_RAM_RESET     = 4'd06,
        STATE_RAM_PREP_1    = 4'd07,
        STATE_RAM_PREP_2    = 4'd08,
        STATE_RAM_SCAN      = 4'd09,
        STATE_RAM_POST      = 4'd10,
        STATE_RAM_S2P_PAD   = 4'd11,
        STATE_WAIT_FOR_DMA  = 4'd12;

/*

    * Scan flow pseudocode:

    default assignments:
        s_read_addr_valid = 0;
        s_read_count_valid = 0;
        s_write_addr_valid = 0;
        s_write_count_valid = 0;
        s2p_p2s_rst = 0;
        s2p_valid = 0;
        s2p_data = 0;
        ff_se = 0;
        ram_sr = 0;
        ram_se = 0;

    STATE_IDLE:
        loop until dma_start;

    STATE_SEND_ADDR:
        if (direction) {
            s_read_addr_valid = 1;
            loop until s_read_addr_ready;
        }
        else {
            s_write_addr_valid = 1;
            loop until s_write_addr_ready;
        }

    STATE_SEND_COUNT:
        if (direction) {
            s_read_count_valid = 1;
            loop until s_read_count_ready;
        }
        else {
            s_write_count_valid = 1;
            loop until s_write_count_ready;
        }

    STATE_FF_RESET:
        ff_cnt <= 0;
        s2p_p2s_rst = 1;
        if (FF_COUNT == 0)
            next STATE_RAM_RESET;

    STATE_FF_SCAN:
        s2p_data = ff_do;
        if (scan_valid) {
            ff_se = 1;
            ff_cnt <= ff_cnt + 1;
        }
        p2s_ready = dma_direction;
        s2p_valid = !dma_direction;
        loop until ff_last;
        if (dma_direction || FF_COUNT % 64 == 0)
            next STATE_RAM_RESET;

    STATE_FF_S2P_PAD:
        s2p_valid = 1;
        loop until s_write_data_valid;

    STATE_RAM_RESET:
        ram_sr = 1;
        ram_cnt <= 0;
        s2p_p2s_rst = 1;
        if (MEM_COUNT == 0)
            next STATE_IDLE;
        else if (dma_direction)
            next STATE_RAM_SCAN;

    STATE_RAM_PREP_1:
        ram_se = 1;

    STATE_RAM_PREP_2:
        ram_se = 1;

    STATE_RAM_SCAN:
        s2p_data = ram_do;
        if (scan_valid) {
            ram_se = 1;
            ram_cnt <= ram_cnt + 1;
        }
        p2s_ready = dma_direction;
        s2p_valid = !dma_direction;
        loop until ram_last;
        if (!dma_direction) {
            if (MEM_COUNT % 64 == 0)
                next STATE_IDLE;
            else
                next STATE_RAM_S2P_PAD;
        }

    STATE_RAM_POST:
        ram_se = 1;
        next STATE_WAIT_FOR_DMA;

    STATE_RAM_S2P_PAD:
        s2p_valid = 1;
        loop until s_write_data_valid;

    STATE_WAIT_FOR_DMA:
        p2s_ready = dma_direction;
        if (dma_direction)
            loop until r_idle;
        else
            loop until w_idle;

*/

    reg [3:0] state, state_next;

    always @(posedge host_clk) begin
        if (host_rst)
            state <= STATE_IDLE;
        else
            state <= state_next;
    end

    always @* begin
        state_next = STATE_IDLE;
        case (state)
            STATE_IDLE:         if (dma_start)                  state_next = STATE_SEND_ADDR;
                                else                            state_next = STATE_IDLE;
            STATE_SEND_ADDR:    if (dma_addr_ready)             state_next = STATE_SEND_COUNT;
                                else                            state_next = STATE_SEND_ADDR;
            STATE_SEND_COUNT:   if (dma_count_ready)            state_next = STATE_FF_RESET;
                                else                            state_next = STATE_SEND_COUNT;
            STATE_FF_RESET:     if (FF_COUNT == 0)              state_next = STATE_RAM_RESET;
                                else                            state_next = STATE_FF_SCAN;
            STATE_FF_SCAN:      if (!ff_last)                   state_next = STATE_FF_SCAN;
                                else if (dma_direction)         state_next = STATE_RAM_RESET;
                                else if (FF_COUNT % 64 == 0)    state_next = STATE_RAM_RESET;
                                else                            state_next = STATE_FF_S2P_PAD;
            STATE_FF_S2P_PAD:   if (s_write_data_valid)         state_next = STATE_RAM_RESET;
                                else                            state_next = STATE_FF_S2P_PAD;
            STATE_RAM_RESET:    if (MEM_COUNT == 0)             state_next = STATE_IDLE;
                                else if (dma_direction)         state_next = STATE_RAM_SCAN;
                                else                            state_next = STATE_RAM_PREP_1;
            STATE_RAM_PREP_1:                                   state_next = STATE_RAM_PREP_2;
            STATE_RAM_PREP_2:                                   state_next = STATE_RAM_SCAN;
            STATE_RAM_SCAN:     if (!ram_last)                  state_next = STATE_RAM_SCAN;
                                else if (dma_direction)         state_next = STATE_RAM_POST;
                                else if (MEM_COUNT % 64 == 0)   state_next = STATE_IDLE;
                                else                            state_next = STATE_RAM_S2P_PAD;
            STATE_RAM_POST:                                     state_next = STATE_WAIT_FOR_DMA;
            STATE_RAM_S2P_PAD:  if (s_write_data_valid)         state_next = STATE_WAIT_FOR_DMA;
                                else                            state_next = STATE_RAM_S2P_PAD;
            STATE_WAIT_FOR_DMA: if (dma_idle)                   state_next = STATE_IDLE;
                                else                            state_next = STATE_WAIT_FOR_DMA;
        endcase
    end

    assign s_read_addr_valid      = state == STATE_SEND_ADDR && dma_direction;
    assign s_write_addr_valid     = state == STATE_SEND_ADDR && !dma_direction;
    assign s_read_count_valid     = state == STATE_SEND_COUNT && dma_direction;
    assign s_write_count_valid    = state == STATE_SEND_COUNT && !dma_direction;

    assign s2p_p2s_rst = state == STATE_FF_RESET || state == STATE_RAM_RESET;

    assign p2s_ready =  dma_direction && (
                        state == STATE_FF_SCAN ||
                        state == STATE_RAM_SCAN ||
                        state == STATE_WAIT_FOR_DMA);

    assign s2p_valid =  !dma_direction && (
                        state == STATE_FF_SCAN ||
                        state == STATE_FF_S2P_PAD ||
                        state == STATE_RAM_SCAN ||
                        state == STATE_RAM_S2P_PAD);

    assign s2p_data =   ff_do & (state == STATE_FF_SCAN) |
                        ram_do & (state == STATE_RAM_SCAN);

    assign ff_se = scan_valid && state == STATE_FF_SCAN;

    assign ram_sr = state == STATE_RAM_RESET;

    assign ram_se =
        state == STATE_RAM_PREP_1 ||
        state == STATE_RAM_PREP_2 ||
        scan_valid && state == STATE_RAM_SCAN ||
        state == STATE_RAM_POST;

    assign dma_running = state != STATE_IDLE;

    localparam CNT_BITS_FF  = $clog2(FF_COUNT + 1);
    localparam CNT_BITS_RAM = $clog2(MEM_COUNT + 1);

    reg [CNT_BITS_FF-1:0] ff_cnt;
    reg [CNT_BITS_RAM-1:0] ram_cnt;

    always @(posedge host_clk) begin
        if (state == STATE_FF_RESET)
            ff_cnt <= 0;
        else if (scan_valid && state == STATE_FF_SCAN)
            ff_cnt <= ff_cnt + 1;
    end

    always @(posedge host_clk) begin
        if (state == STATE_RAM_RESET)
            ram_cnt <= 0;
        else if (scan_valid && state == STATE_RAM_SCAN)
            ram_cnt <= ram_cnt + 1;
    end

    assign ff_last = scan_valid && state == STATE_FF_SCAN && ff_cnt == FF_COUNT - 1;
    assign ram_last = scan_valid && state == STATE_RAM_SCAN && ram_cnt == MEM_COUNT - 1;

    if (FF_COUNT == 0)
        assign ff_di = 64'd0; // to avoid combinational logic loop
    else
        assign ff_di = dma_direction ? p2s_data : ff_do;

    assign ram_di = p2s_data;
    assign ram_sd = dma_direction;

endmodule
