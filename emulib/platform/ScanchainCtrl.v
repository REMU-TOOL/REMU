`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"

module ScanchainCtrl #(
    parameter       FF_COUNT        = 0,
    parameter       MEM_COUNT       = 0,
    parameter       FF_WIDTH        = 64,
    parameter       MEM_WIDTH       = 64,

    parameter       __CKPT_FF_CNT   = (FF_COUNT * FF_WIDTH + 63) / 64,
    parameter       __CKPT_MEM_CNT  = (MEM_COUNT * MEM_WIDTH + 63) / 64,
    parameter       __CKPT_CNT      = __CKPT_FF_CNT + __CKPT_MEM_CNT,
    parameter       __CKPT_PAGES    = (__CKPT_CNT * 8 + 'hfff) / 'h1000
)(

    input  wire         host_clk,
    input  wire         host_rst,

    output wire         ff_se,
    output wire [63:0]  ff_di,
    input  wire [63:0]  ff_do,
    output wire         ram_sr,
    output wire         ram_se,
    output wire         ram_sd,
    output wire [63:0]  ram_di,
    input  wire [63:0]  ram_do,

    input  wire         ctrl_wen,
    input  wire [ 5:0]  ctrl_waddr,
    input  wire [31:0]  ctrl_wdata,
    input  wire         ctrl_ren,
    input  wire [ 5:0]  ctrl_raddr,
    output reg  [31:0]  ctrl_rdata,

    (* __emu_extern_intf_addr_pages = __CKPT_PAGES *)
    (* __emu_extern_intf = "dma_axi" *)
    output wire                     dma_axi_awvalid,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire                     dma_axi_awready,
    (* __emu_extern_intf = "dma_axi", __emu_extern_intf_type = "address" *)
    output wire [31:0]              dma_axi_awaddr,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [7:0]               dma_axi_awlen,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [2:0]               dma_axi_awsize,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [1:0]               dma_axi_awburst,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [0:0]               dma_axi_awlock,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [3:0]               dma_axi_awcache,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [2:0]               dma_axi_awprot,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [3:0]               dma_axi_awqos,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [3:0]               dma_axi_awregion,
    (* __emu_extern_intf = "dma_axi" *)
    output wire                     dma_axi_wvalid,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire                     dma_axi_wready,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [63:0]              dma_axi_wdata,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [7:0]               dma_axi_wstrb,
    (* __emu_extern_intf = "dma_axi" *)
    output wire                     dma_axi_wlast,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire                     dma_axi_bvalid,
    (* __emu_extern_intf = "dma_axi" *)
    output wire                     dma_axi_bready,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire [1:0]               dma_axi_bresp,
    (* __emu_extern_intf = "dma_axi" *)
    output wire                     dma_axi_arvalid,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire                     dma_axi_arready,
    (* __emu_extern_intf = "dma_axi", __emu_extern_intf_type = "address" *)
    output wire [31:0]              dma_axi_araddr,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [7:0]               dma_axi_arlen,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [2:0]               dma_axi_arsize,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [1:0]               dma_axi_arburst,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [0:0]               dma_axi_arlock,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [3:0]               dma_axi_arcache,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [2:0]               dma_axi_arprot,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [3:0]               dma_axi_arqos,
    (* __emu_extern_intf = "dma_axi" *)
    output wire [3:0]               dma_axi_arregion,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire                     dma_axi_rvalid,
    (* __emu_extern_intf = "dma_axi" *)
    output wire                     dma_axi_rready,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire [63:0]              dma_axi_rdata,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire [1:0]               dma_axi_rresp,
    (* __emu_extern_intf = "dma_axi" *)
    input  wire                     dma_axi_rlast

);

    localparam  DMA_CTRL    = 6'h00;

    // DMA_CTRL
    //      [0]     -> RUNNING [WARL]
    //      [1]     -> DIRECTION [WARL]

    reg dma_running, dma_direction;
    wire [31:0] dma_ctrl;
    assign dma_ctrl[31:2]   = 30'd0;
    assign dma_ctrl[1]      = dma_direction;
    assign dma_ctrl[0]      = dma_running;

    always @(posedge clk) begin
        if (rst) begin
            dma_running     <= 1'b0;
            dma_direction   <= 1'b0;
        end
        else begin
            if (!dma_running && ctrl_wen && ctrl_waddr == DMA_CTRL) begin
                dma_running     <= ctrl_wdata[0];
                dma_direction   <= ctrl_wdata[1];
            end
        end
    end

    always @* begin
        case (ctrl_raddr)
            DMA_CTRL:   ctrl_rdata = dma_ctrl;
            default:    ctrl_rdata = 32'd0;
        endcase
    end

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

    emulib_simple_dma #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (64),
        .COUNT_WIDTH    ($clog2(__CKPT_CNT))
    )
    u_dma(

        .clk                    (clk),
        .rst                    (rst),

        .s_read_addr_valid      (s_read_addr_valid),
        .s_read_addr_ready      (s_read_addr_ready),
        .s_read_addr            (32'd0),

        .s_read_count_valid     (s_read_count_valid),
        .s_read_count_ready     (s_read_count_ready),
        .s_read_count           (__CKPT_CNT),

        .m_read_data_valid      (m_read_data_valid),
        .m_read_data_ready      (m_read_data_ready),
        .m_read_data            (m_read_data),

        .s_write_addr_valid     (s_write_addr_valid),
        .s_write_addr_ready     (s_write_addr_ready),
        .s_write_addr           (32'd0),

        .s_write_count_valid    (s_write_count_valid),
        .s_write_count_ready    (s_write_count_ready),
        .s_write_count          (__CKPT_CNT),

        .s_write_data_valid     (s_write_data_valid),
        .s_write_data_ready     (s_write_data_ready),
        .s_write_data           (s_write_data),

        `AXI4_CONNECT_NO_ID     (m_axi, dma_axi),

        .r_idle                 (r_idle),
        .w_idle                 (w_idle)

    );

    wire dma_addr_ready = dma_direction ? read_addr_ready : write_addr_ready;
    wire dma_count_ready = dma_direction ? read_count_ready : write_count_ready;

    // DUT & scan logic

    // operation sequence
    // (<L> = last data, N = FF_COUNT or MEM_COUNT)
    // scan-out:
    // FF SCAN      0   1   1   ..  1   0   0   0   0   ..  0   0
    // FF LAST      0   0   0   ..  1   0   0   0   0   ..  0   0
    // FF DATA      x  <0> <1>  .. <L>  x   x   x   x   ..  x   x
    // FF CNT       0   1   2   ..  N   0   0   0   0   ..  0   0
    // RAM SCAN     0   0   0   ..  0   1   1   1   1   ..  1   0
    // RAM LAST     0   0   0   ..  0   0   0   0   0   ..  1   0
    // RAM DATA     x   x   x   ..  x   x   x  <0> <1>  .. <L>  x
    // RAM CNT      0   0   0   ..  0   0   0   1   2   ..  N   0
    // scan-in:
    // FF SCAN      0   1   1   ..  1   0   0   ..  0   0
    // FF LAST      0   0   0   ..  1   0   0   ..  0   0
    // FF DATA      x  <0> <1>  .. <L>  x   x   ..  x   x
    // FF CNT       0   1   2   ..  N   0   0   ..  0   0
    // RAM SCAN     0   0   0   ..  0   1   1   ..  1   0
    // RAM LAST     0   0   0   ..  0   0   0   ..  1   0
    // RAM DATA     x   x   x   ..  x  <0> <1>  .. <L>  x
    // RAM CNT      0   0   0   ..  0   1   2   ..  N   0

    wire ff_last, ram_last;

    localparam [3:0]
        STATE_IDLE          = 4'd0,
        STATE_SEND_ADDR     = 4'd1,
        STATE_SEND_COUNT    = 4'd2,
        STATE_FF_RESET      = 4'd3,
        STATE_FF_SCAN       = 4'd4,
        STATE_RAM_RESET     = 4'd5,
        STATE_RAM_PREP_1    = 4'd6,
        STATE_RAM_PREP_2    = 4'd7,
        STATE_RAM_SCAN      = 4'd8;

    reg [3:0] state, state_next;

    always @(posedge host_clk) begin
        if (host_rst)
            state <= STATE_IDLE;
        else
            state <= state_next;
    end

    always @* begin
        case (state)
            STATE_IDLE:         state_next = dma_running ? STATE_SEND_ADDR : STATE_IDLE;
            STATE_SEND_ADDR:    state_next = dma_addr_ready ? STATE_SEND_COUNT : STATE_SEND_ADDR;
            STATE_SEND_COUNT:   state_next = dma_count_ready ? STATE_FF_RESET : STATE_SEND_COUNT;
            STATE_FF_RESET:     state_next = FF_COUNT == 0 ? STATE_RAM_RESET : STATE_FF_SCAN;
            STATE_FF_SCAN:      state_next = ff_last ? STATE_RAM_RESET : STATE_FF_SCAN;
            STATE_RAM_RESET:    state_next = MEM_COUNT == 0 ? STATE_IDLE :
                                            (dma_direction ? STATE_RAM_SCAN : STATE_RAM_PREP_1);
            STATE_RAM_PREP_1:   state_next = STATE_RAM_PREP_2;
            STATE_RAM_PREP_2:   state_next = STATE_RAM_SCAN;
            STATE_RAM_SCAN:     state_next = ram_last ? STATE_IDLE : STATE_RAM_SCAN;
            default:            state_next = STATE_IDLE;
        endcase
    end

    localparam CNT_BITS_FF  = $clog2(FF_COUNT + 1);
    localparam CNT_BITS_RAM = $clog2(MEM_COUNT + 1);

    reg [CNT_BITS_FF-1:0] ff_cnt;
    reg [CNT_BITS_RAM-1:0] ram_cnt;

    always @(posedge host_clk) begin
        if (state == STATE_FF_RESET)
            ff_cnt <= 0;
        else if (state == STATE_FF_SCAN)
            ff_cnt <= ff_cnt + 1;
    end

    always @(posedge host_clk) begin
        if (state == STATE_RAM_RESET)
            ram_cnt <= 0;
        else if (state == STATE_RAM_SCAN)
            ram_cnt <= ram_cnt + 1;
    end

    assign ff_last = state == STATE_FF_SCAN && ff_cnt == FF_COUNT - 1;
    assign ram_last = state == STATE_RAM_SCAN && ram_cnt == MEM_COUNT - 1;

    wire scan_valid = dma_direction ? read_data_valid : write_data_ready;

    assign ff_se = scan_valid && state == STATE_FF_SCAN;

    if (FF_COUNT == 0)
        assign ff_di = 64'd0; // to avoid combinational logic loop
    else
        assign ff_di = dma_direction ? read_data : ff_do;

    assign ram_se = scan_valid && (
        state == STATE_RAM_PREP_1 ||
        state == STATE_RAM_PREP_2 ||
        state == STATE_RAM_SCAN);

    assign ram_di = read_data;
    assign ram_sd = dma_direction;

    assign read_data_ready = dma_direction && (
        state == STATE_FF_SCAN ||
        state == STATE_RAM_SCAN);

    assign write_data_valid = !dma_direction && (
        state == STATE_FF_SCAN ||
        state == STATE_RAM_SCAN);

    assign write_data =
        {64{state == STATE_FF_SCAN}} & ff_do |
        {64{state == STATE_RAM_SCAN}} & ram_do;

    assign read_addr_valid      = state == STATE_SEND_ADDR && dma_direction;
    assign write_addr_valid     = state == STATE_SEND_ADDR && !dma_direction;
    assign read_count_valid     = state == STATE_SEND_COUNT && dma_direction;
    assign write_count_valid    = state == STATE_SEND_COUNT && !dma_direction;

endmodule

`default_nettype wire
