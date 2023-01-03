`timescale 1ns / 1ps

module emulib_axis_width_converter #(
    parameter   S_TDATA_BYTES   = 1,
    parameter   M_TDATA_BYTES   = 1,
    parameter   BYTE_WIDTH      = 8
)(
    input  wire                                 clk,
    input  wire                                 rst,

    input  wire                                 s_tvalid,
    output wire                                 s_tready,
    input  wire [BYTE_WIDTH*S_TDATA_BYTES-1:0]  s_tdata,
    input  wire [S_TDATA_BYTES-1:0]             s_tkeep,
    input  wire                                 s_tlast,

    output wire                                 m_tvalid,
    input  wire                                 m_tready,
    output wire [BYTE_WIDTH*M_TDATA_BYTES-1:0]  m_tdata,
    output wire [M_TDATA_BYTES-1:0]             m_tkeep,
    output wire                                 m_tlast
);

    `include "gcd_lcm.vh"

    // intermediate layer

    localparam I_TDATA_BYTES = f_lcm(S_TDATA_BYTES, M_TDATA_BYTES);

    wire                                 i_tvalid;
    wire                                 i_tready;
    wire [BYTE_WIDTH*I_TDATA_BYTES-1:0]  i_tdata;
    wire [I_TDATA_BYTES-1:0]             i_tkeep;
    wire                                 i_tlast;

    if (S_TDATA_BYTES == I_TDATA_BYTES) begin
        assign i_tvalid = s_tvalid;
        assign s_tready = i_tready;
        assign i_tdata  = s_tdata;
        assign i_tkeep  = s_tkeep;
        assign i_tlast  = s_tlast;
    end
    else begin
        emulib_axis_width_upsizer #(
            .S_TDATA_BYTES  (S_TDATA_BYTES),
            .M_TDATA_BYTES  (I_TDATA_BYTES),
            .BYTE_WIDTH     (BYTE_WIDTH)
        ) upsizer (
            .clk        (clk),
            .rst        (rst),
            .s_tvalid   (s_tvalid),
            .s_tready   (s_tready),
            .s_tdata    (s_tdata),
            .s_tkeep    (s_tkeep),
            .s_tlast    (s_tlast),
            .m_tvalid   (i_tvalid),
            .m_tready   (i_tready),
            .m_tdata    (i_tdata),
            .m_tkeep    (i_tkeep),
            .m_tlast    (i_tlast)
        );
    end

    if (I_TDATA_BYTES == M_TDATA_BYTES) begin
        assign m_tvalid = i_tvalid;
        assign i_tready = m_tready;
        assign m_tdata  = i_tdata;
        assign m_tkeep  = i_tkeep;
        assign m_tlast  = i_tlast;
    end
    else begin
        emulib_axis_width_downsizer #(
            .S_TDATA_BYTES  (I_TDATA_BYTES),
            .M_TDATA_BYTES  (M_TDATA_BYTES),
            .BYTE_WIDTH     (BYTE_WIDTH)
        ) downsizer (
            .clk        (clk),
            .rst        (rst),
            .s_tvalid   (i_tvalid),
            .s_tready   (i_tready),
            .s_tdata    (i_tdata),
            .s_tkeep    (i_tkeep),
            .s_tlast    (i_tlast),
            .m_tvalid   (m_tvalid),
            .m_tready   (m_tready),
            .m_tdata    (m_tdata),
            .m_tkeep    (m_tkeep),
            .m_tlast    (m_tlast)
        );
    end

endmodule
