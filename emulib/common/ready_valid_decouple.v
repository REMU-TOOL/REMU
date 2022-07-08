`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_decouple #(
    parameter   DECOUPLE_S  = 1,
    parameter   DECOUPLE_M  = 1
)(
    input  wire     i_valid,
    output wire     i_ready,

    output wire     o_valid,
    input  wire     o_ready,

    input  wire     couple
);

    if (DECOUPLE_S)
        assign s_ready = m_ready && couple;
    else
        assign s_ready = m_ready;

    if (DECOUPLE_M)
        assign m_valid = s_valid && couple;
    else
        assign m_valid = s_valid;

endmodule

`default_nettype wire
