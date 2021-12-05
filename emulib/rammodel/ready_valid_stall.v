`timescale 1ns / 1ps

module ready_valid_stall_s #(
    parameter   DATA_WIDTH      = 1
)(
    input                           s_valid,
    input       [DATA_WIDTH-1:0]    s_data,
    output                          s_ready,

    output                          m_valid,
    output      [DATA_WIDTH-1:0]    m_data,
    input                           m_ready,

    input                           stall
);

    assign s_ready  = m_ready;
    assign m_valid  = s_valid && !stall;
    assign m_data   = s_data;

endmodule

module ready_valid_stall_m #(
    parameter   DATA_WIDTH      = 1
)(
    input                           s_valid,
    input       [DATA_WIDTH-1:0]    s_data,
    output                          s_ready,

    output                          m_valid,
    output      [DATA_WIDTH-1:0]    m_data,
    input                           m_ready,

    input                           stall
);

    assign s_ready  = m_ready && !stall;
    assign m_valid  = s_valid;
    assign m_data   = s_data;

endmodule
