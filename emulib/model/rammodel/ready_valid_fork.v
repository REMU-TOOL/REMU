`resetall
`timescale 1ns / 1ps
`default_nettype none

module ready_valid_fork #(
    parameter   DATA_WIDTH      = 1
)(
    input  wire                         s_valid,
    input  wire     [DATA_WIDTH-1:0]    s_data,
    output wire                         s_ready,

    output wire                         m1_valid,
    output wire     [DATA_WIDTH-1:0]    m1_data,
    input  wire                         m1_ready,

    output wire                         m2_valid,
    output wire     [DATA_WIDTH-1:0]    m2_data,
    input  wire                         m2_ready
);

    assign m1_data      = s_data;
    assign m2_data      = s_data;
    assign m1_valid     = s_valid && m2_ready;
    assign m2_valid     = s_valid && m1_ready;
    assign s_ready      = m1_ready && m2_ready;

endmodule

`resetall
