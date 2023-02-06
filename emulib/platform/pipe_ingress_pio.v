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
    output reg  [31:0]                  ctrl_rdata,

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

    wire data_valid, data_ready;
    wire null_valid, null_ready;

    // Registers
    // 0x00 -> ADAPTER_CTRL
    // 0x04 -> DATA_STAT [RO] DATA_IN [WO]
    // 0x08 -> DATA_CNT
    // 0x0c -> NULL_CNT

    // Write logic

    reg w_adapter_ctrl;
    reg w_data_in;
    reg w_data_cnt;
    reg w_null_cnt;

    always @* begin
        w_adapter_ctrl = 1'b0;
        w_data_in = 1'b0;
        w_data_cnt = 1'b0;
        w_null_cnt = 1'b0;
        case (ctrl_waddr[3:2])
            2'h0:   w_adapter_ctrl = 1'b1;
            2'h1:   w_data_in = 1'b1;
            2'h2:   w_data_cnt = 1'b1;
            2'h3:   w_null_cnt = 1'b1;
        endcase
    end

    // ADAPTER_CTRL
    // [0]      -> enable
    // [1]      -> buffer_clear [WO]
    // [7:4]    -> data_tkeep
    // [8]      -> data_tlast

    reg enable;
    reg [3:0] data_tkeep;
    reg data_tlast;

    always @(posedge clk) begin
        if (rst) begin
            enable <= 1'b0;
            data_tkeep <= 4'b1111;
            data_tlast <= 1'b0;
        end
        else if (ctrl_wen && w_adapter_ctrl) begin
            enable <= ctrl_wdata[0];
            data_tkeep <= ctrl_wdata[7:4];
            data_tlast <= ctrl_wdata[8];
        end
    end

    assign buffer_soft_rst = ctrl_wen && w_adapter_ctrl && ctrl_wdata[1];

    assign pre_conv_tkeep = data_tkeep;
    assign pre_conv_tlast = data_tlast;

    wire [31:0] adapter_ctrl = {
        23'd0,
        data_tlast,
        data_tkeep,
        3'd0,
        enable
    };

    // DATA_STAT [RO]
    // [0]      -> ready

    wire [31:0] data_stat = {31'd0, pre_conv_tready};

    // DATA_IN [WO]

    assign pre_conv_tdata = ctrl_wdata;
    assign pre_conv_tvalid = ctrl_wen && w_data_in;

    // DATA_CNT

    reg [31:0] data_cnt;
    wire data_cnt_empty = data_cnt == 32'd0;

    always @(posedge clk) begin
        if (rst)
            data_cnt <= 32'd0;
        else if (ctrl_wen && w_data_cnt)
            data_cnt <= ctrl_wdata;
        else if (data_valid && data_ready)
            data_cnt <= data_cnt - 32'd1;
    end

    // NULL_CNT

    reg [31:0] null_cnt;
    wire null_cnt_empty = null_cnt == 32'd0;

    always @(posedge clk) begin
        if (rst)
            null_cnt <= 32'd0;
        else if (ctrl_wen && w_null_cnt)
            null_cnt <= ctrl_wdata;
        else if (null_valid && null_ready)
            null_cnt <= null_cnt - 32'd1;
    end

    // Read logic

    always @* begin
        ctrl_rdata = 32'd0;
        case (ctrl_raddr[3:2])
            2'h0:   ctrl_rdata = adapter_ctrl;
            2'h1:   ctrl_rdata = data_stat;
            2'h2:   ctrl_rdata = data_cnt;
            2'h3:   ctrl_rdata = null_cnt;
        endcase
    end

    // data throttling

    assign data_valid = buffered_valid && !data_cnt_empty;
    assign buffered_ready = data_ready && !data_cnt_empty;

    // null throttling

    assign null_valid = !null_cnt_empty;

    // data & null arbitration (data > null)

    assign stream_valid     = enable && (data_valid || null_valid);
    assign stream_data      = buffered_data;
    assign stream_empty     = !data_valid;
    assign data_ready       = enable && stream_ready;
    assign null_ready       = enable && stream_ready && !data_valid;

endmodule
