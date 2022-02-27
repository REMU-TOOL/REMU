`resetall
`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_mux #(
    parameter   NUM_S   = 1,
    parameter   NUM_M   = 1
)(
    input  wire [NUM_S-1:0]     s_valid,
    output wire [NUM_S-1:0]     s_ready,
    input  wire [NUM_S-1:0]     s_sel,

    output wire [NUM_M-1:0]     m_valid,
    input  wire [NUM_M-1:0]     m_ready,
    input  wire [NUM_S-1:0]     m_sel
);

    wire valid = |(s_valid & s_sel);
    wire ready = |(m_ready & m_sel);

    assign m_valid = {NUM_M{valid}} & m_sel;
    assign s_ready = {NUM_S{ready}} & s_sel;

endmodule

`resetall
