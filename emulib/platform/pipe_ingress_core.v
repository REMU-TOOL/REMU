`timescale 1ns / 1ps

module IngressPipeCore #(
    parameter   DBUS_WIDTH      = 32,
    parameter   DBUS_BYTES      = DBUS_WIDTH / 8,
    parameter   DATA_WIDTH      = 1,
    parameter   FIFO_DEPTH      = 16
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                     rec_mode,

    input  wire                     dbus_tvalid,
    input  wire [DBUS_WIDTH-1:0]    dbus_tdata,
    input  wire [DBUS_BYTES-1:0]    dbus_tkeep,
    input  wire                     dbus_tlast,
    output wire                     dbus_tready,

    input  wire                     cnts_valid,
    input  wire [63:0]              cnts_data,
    output wire                     cnts_ready,

    output wire                     rec_cnts_valid,
    output wire [63:0]              rec_cnts_data,
    input  wire                     rec_cnts_ready,

    output wire                     stream_valid,
    output wire [DATA_WIDTH-1:0]    stream_data,
    output wire                     stream_empty,
    input  wire                     stream_ready
);

    localparam DATA_BYTES = (DATA_WIDTH + 7) / 8;

    wire                    dbus_conv_tvalid;
    wire                    dbus_conv_tready;
    wire [DATA_BYTES*8-1:0] dbus_conv_tdata;
    wire [DATA_BYTES-1:0]   dbus_conv_tkeep;
    wire                    dbus_conv_tlast;

    emulib_axis_width_converter #(
        .S_TDATA_BYTES  (DBUS_BYTES),
        .M_TDATA_BYTES  (DATA_BYTES)
    ) data_width_conv (
        .clk        (clk),
        .rst        (rst),
        .s_tvalid   (dbus_tvalid),
        .s_tready   (dbus_tready),
        .s_tdata    (dbus_tdata),
        .s_tkeep    (dbus_tkeep),
        .s_tlast    (dbus_tlast),
        .m_tvalid   (dbus_conv_tvalid),
        .m_tready   (dbus_conv_tready),
        .m_tdata    (dbus_conv_tdata),
        .m_tkeep    (dbus_conv_tkeep),
        .m_tlast    (dbus_conv_tlast)
    );

    wire                    buffered_valid;
    wire                    buffered_ready;
    wire [DATA_WIDTH-1:0]   buffered_data;

    emulib_ready_valid_fifo #(
        .WIDTH  (DATA_WIDTH),
        .DEPTH  (FIFO_DEPTH)
    ) data_fifo (
        .clk    (clk),
        .rst    (rst),
        .ivalid (dbus_conv_tvalid),
        .iready (dbus_conv_tready),
        .idata  (dbus_conv_tdata[DATA_WIDTH-1:0]),
        .ovalid (buffered_valid),
        .oready (buffered_ready),
        .odata  (buffered_data)
    );



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
