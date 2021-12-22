`timescale 1ns / 1ps

module ready_valid_stall #(
    parameter   DATA_WIDTH      = 1,
    parameter   STALL_S         = 1,
    parameter   STALL_M         = 1
)(
    input                           s_valid,
    input       [DATA_WIDTH-1:0]    s_data,
    output                          s_ready,

    output                          m_valid,
    output      [DATA_WIDTH-1:0]    m_data,
    input                           m_ready,

    input                           stall
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
