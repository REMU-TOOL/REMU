`resetall
`timescale 1ns / 1ps
`default_nettype none

module ready_valid_stall #(
    parameter   DATA_WIDTH      = 1,
    parameter   STALL_S         = 1,
    parameter   STALL_M         = 1
)(
    input  wire                         s_valid,
    input  wire     [DATA_WIDTH-1:0]    s_data,
    output wire                         s_ready,

    output wire                         m_valid,
    output wire     [DATA_WIDTH-1:0]    m_data,
    input  wire                         m_ready,

    input  wire                         stall
);

    if (STALL_S)
        assign s_ready = m_ready && !stall;
    else
        assign s_ready = m_ready;

    if (STALL_M)
        assign m_valid = s_valid && !stall;
    else
        assign m_valid = s_valid;

    assign m_data = s_data;

endmodule

`resetall
