`timescale 1ns / 1ps

module IngressPipePIOAdapter #(
    parameter   CTRL_ADDR_WIDTH = 32,

    parameter   DATA_WIDTH  = 1,
    parameter   FIFO_DEPTH  = 16
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                         ctrl_wen,
    input  wire [CTRL_ADDR_WIDTH-1:0]   ctrl_waddr,
    input  wire [31:0]                  ctrl_wdata,
    input  wire                         ctrl_ren,
    input  wire [CTRL_ADDR_WIDTH-1:0]   ctrl_raddr,
    output wire [31:0]                  ctrl_rdata,

    output wire                     stream_valid,
    output wire [DATA_WIDTH-1:0]    stream_data,
    output wire                     stream_empty,
    input  wire                     stream_ready
);

    localparam DATA_BYTES = (DATA_WIDTH + 7) / 8;

    wire buffer_soft_rst;

    wire                    pre_conv_tvalid;
    wire                    pre_conv_tready;
    wire [31:0]             pre_conv_tdata;
    wire [3:0]              pre_conv_tkeep;
    wire                    pre_conv_tlast;

    wire                    conv_tvalid;
    wire                    conv_tready;
    wire [DATA_BYTES*8-1:0] conv_tdata;
    wire [DATA_BYTES-1:0]   conv_tkeep;
    wire                    conv_tlast;

    emulib_axis_width_converter #(
        .S_TDATA_BYTES  (4),
        .M_TDATA_BYTES  (DATA_BYTES)
    ) data_width_conv (
        .clk        (clk),
        .rst        (rst || buffer_soft_rst),
        .s_tvalid   (pre_conv_tvalid),
        .s_tready   (pre_conv_tready),
        .s_tdata    (pre_conv_tdata),
        .s_tkeep    (pre_conv_tkeep),
        .s_tlast    (pre_conv_tlast),
        .m_tvalid   (conv_tvalid),
        .m_tready   (conv_tready),
        .m_tdata    (conv_tdata),
        .m_tkeep    (conv_tkeep),
        .m_tlast    (conv_tlast)
    );

    wire                    buffered_valid;
    wire                    buffered_ready;
    wire [DATA_WIDTH-1:0]   buffered_data;

    emulib_ready_valid_fifo #(
        .WIDTH  (DATA_WIDTH),
        .DEPTH  (FIFO_DEPTH)
    ) data_fifo (
        .clk    (clk),
        .rst    (rst || buffer_soft_rst),
        .ivalid (conv_tvalid),
        .iready (conv_tready),
        .idata  (conv_tdata[DATA_WIDTH-1:0]),
        .ovalid (buffered_valid),
        .oready (buffered_ready),
        .odata  (buffered_data)
    );

    wire stall;
    wire null_valid, null_ready;

    assign stream_valid     = buffered_valid || null_valid;
    assign stream_data      = buffered_data;
    assign stream_empty     = !buffered_valid;
    assign buffered_ready   = stream_ready;
    assign null_ready       = stream_ready && !buffered_valid;

    // Registers
    // 0x00 -> ADAPTER_CTRL
    // 0x04 -> DATA_RST [WO]
    // 0x08 -> DATA_MODE
    // 0x0c -> DATA_READY [RO]
    // 0x10 -> DATA_IN [WO]
    // 0x14 -> DATA_XFER_CNT
    // 0x18 -> NULL_IN_CNT
    // 0x1c -> NULL_XFER_CNT

    // Write logic

    reg w_adapter_ctrl;
    reg w_data_rst;
    reg w_data_mode;
    reg w_data_in;
    reg w_data_xfer_cnt;
    reg w_null_in_cnt;
    reg w_null_xfer_cnt;

    always @* begin
        w_adapter_ctrl = 1'b0;
        w_data_rst = 1'b0;
        w_data_mode = 1'b0;
        w_data_in = 1'b0;
        w_data_xfer_cnt = 1'b0;
        w_null_in_cnt = 1'b0;
        w_null_xfer_cnt = 1'b0;
        case (ctrl_waddr[4:2])
            3'h0:   w_adapter_ctrl = 1'b1;
            3'h1:   w_data_rst = 1'b1;
            3'h2:   w_data_mode = 1'b1;
            // 3'h3 DATA_READY
            3'h4:   w_data_in = 1'b1;
            3'h5:   w_data_xfer_cnt = 1'b1;
            3'h6:   w_null_in_cnt = 1'b1;
            3'h7:   w_null_xfer_cnt = 1'b1;
        endcase
    end

    // ADAPTER_CTRL
    // [0]      -> compact_mode (enable null compression)
    // [1]      -> rec_mode (auto-transfer null data & record count)

    reg compact_mode;
    reg rec_mode;

    always @(posedge clk) begin
        if (rst) begin
            compact_mode <= 1'b1;
            rec_mode <= 1'b0;
        end
        else if (ctrl_wen && w_adapter_ctrl) begin
            compact_mode <= ctrl_wdata[0];
            rec_mode <= ctrl_wdata[1];
        end
    end

    wire [31:0] adapter_ctrl = {30'd0, rec_mode, compact_mode};

    // DATA_RST [WO]

    assign buffer_soft_rst = ctrl_wen && w_data_rst;

    // DATA_MODE
    // [3:0]    -> data_tkeep
    // [4]      -> data_tlast
    // [31]     -> data_null (only valid in non-compact mode)

    reg [3:0] data_tkeep;
    reg data_tlast;
    reg data_null;

    assign pre_conv_tkeep = data_tkeep;
    assign pre_conv_tlast = data_tlast;

    always @(posedge clk) begin
        if (rst) begin
            data_tkeep <= 4'b1111;
            data_tlast <= 1'b0;
            data_null <= 1'b0;
        end
        else if (ctrl_wen && w_data_mode) begin
            data_tkeep <= ctrl_wdata[3:0];
            data_tlast <= ctrl_wdata[4];
            data_null <= ctrl_wdata[31];
        end
    end

    wire [31:0] data_mode = {data_null, 26'd0, data_tlast, data_tkeep};

    // DATA_READY [RO]
    // [0]      -> data_ready

    wire [31:0] data_ready = {31'd0, pre_conv_tready};

    // DATA_IN [WO]

    assign pre_conv_tdata = ctrl_wdata;
    assign pre_conv_tvalid = ctrl_wen && w_data_in;

    // DATA_XFER_CNT

    reg [31:0] data_xfer_cnt;
    wire data_xfer_cnt_full = data_xfer_cnt == 32'hffffffff;

    always @(posedge clk) begin
        if (rst)
            data_xfer_cnt <= 32'd0;
        else if (ctrl_wen && w_data_xfer_cnt)
            data_xfer_cnt <= ctrl_wdata;
        else if (buffered_valid && buffered_ready)
            data_xfer_cnt <= data_xfer_cnt + 32'd1;
    end

    // NULL_IN_CNT

    reg [31:0] null_in_cnt;
    wire null_in_cnt_empty = null_in_cnt == 32'd0;

    always @(posedge clk) begin
        if (rst)
            null_in_cnt <= 32'd0;
        else if (ctrl_wen && w_null_in_cnt)
            null_in_cnt <= ctrl_wdata;
        else if (null_valid && null_ready && !null_in_cnt_empty)
            null_in_cnt <= null_in_cnt - 32'd1;
    end

    // NULL_XFER_CNT

    reg [31:0] null_xfer_cnt;
    wire null_xfer_cnt_full = null_xfer_cnt == 32'hffffffff;

    always @(posedge clk) begin
        if (rst)
            null_xfer_cnt <= 32'd0;
        else if (ctrl_wen && w_null_xfer_cnt)
            null_xfer_cnt <= ctrl_wdata;
        else if (rec_mode && null_valid && null_ready)
            null_xfer_cnt <= null_xfer_cnt + 32'd1;
    end

    // Read logic

    always @* begin
        ctrl_rdata = 32'd0;
        case (ctrl_raddr[4:2])
            3'h0:   ctrl_rdata = adapter_ctrl;
            // 3'h1 DATA_RST
            3'h2:   ctrl_rdata = data_mode;
            3'h3:   ctrl_rdata = data_ready;
            // 3'h4 DATA_IN
            3'h5:   ctrl_rdata = data_xfer_cnt;
            3'h6:   ctrl_rdata = null_in_cnt;
            3'h7:   ctrl_rdata = null_xfer_cnt;
        endcase
    end

    assign stall = data_xfer_cnt_full || null_xfer_cnt_full;
    assign null_valid = rec_mode || !null_in_cnt_empty;

endmodule
