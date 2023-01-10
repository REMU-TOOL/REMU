`timescale 1ns / 1ps

module EgressPipePIOAdapter #(
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

    input  wire                     stream_valid,
    input  wire [DATA_WIDTH-1:0]    stream_data,
    output wire                     stream_ready
);

    localparam DATA_BYTES = (DATA_WIDTH + 7) / 8;

    wire                    buffered_valid;
    wire                    buffered_ready;
    wire [DATA_WIDTH-1:0]   buffered_data;

    wire [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;

    emulib_ready_valid_fifo #(
        .WIDTH  (DATA_WIDTH),
        .DEPTH  (FIFO_DEPTH)
    ) data_fifo (
        .clk    (clk),
        .rst    (rst),
        .ivalid (stream_valid),
        .iready (stream_data),
        .idata  (stream_ready),
        .ovalid (buffered_valid),
        .oready (buffered_ready),
        .odata  (buffered_data),
        .count  (fifo_count)
    );

    wire pre_conv_tlast = fifo_count == 1;

    wire                    conv_tvalid;
    wire                    conv_tready;
    wire [31:0]             conv_tdata;
    wire [3:0]              conv_tkeep;
    wire                    conv_tlast;

    emulib_axis_width_converter #(
        .S_TDATA_BYTES  (DATA_BYTES),
        .M_TDATA_BYTES  (4)
    ) data_width_conv (
        .clk        (clk),
        .rst        (rst),
        .s_tvalid   (buffered_valid),
        .s_tready   (buffered_ready),
        .s_tdata    (buffered_data),
        .s_tkeep    ({DATA_BYTES{1'b1}}),
        .s_tlast    (pre_conv_tlast),
        .m_tvalid   (conv_tvalid),
        .m_tready   (conv_tready),
        .m_tdata    (conv_tdata),
        .m_tkeep    (conv_tkeep),
        .m_tlast    (conv_tlast)
    );

    // Registers
    // 0x00 -> DATA_STAT [RO]
    // 0x04 -> DATA_OUT [RO]

    // DATA_STAT [RO]
    // [3:0]    -> data_tkeep
    // [4]      -> data_tlast
    // [31]     -> data_tvalid

    wire [31:0] data_stat = {conv_tvalid, 26'd0, conv_tlast, conv_tkeep};

    // DATA_OUT [RO]

    wire [31:0] data_out = conv_tdata;

    // Read logic

    always @* begin
        ctrl_rdata = 32'd0;
        case (ctrl_raddr[2:2])
            1'h0:   ctrl_rdata = data_stat;
            1'h1:   ctrl_rdata = data_out;
        endcase
    end

    assign conv_tready = ctrl_ren && ctrl_raddr[2:2] == 1'h1;

endmodule
