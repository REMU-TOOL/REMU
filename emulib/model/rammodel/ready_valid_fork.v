`timescale 1ns / 1ps

module ready_valid_fork #(
    parameter   DATA_WIDTH      = 1
)(
    input                           s_valid,
    input       [DATA_WIDTH-1:0]    s_data,
    output                          s_ready,

    output                          m1_valid,
    output      [DATA_WIDTH-1:0]    m1_data,
    input                           m1_ready,

    output                          m2_valid,
    output      [DATA_WIDTH-1:0]    m2_data,
    input                           m2_ready
);

    assign m1_data      = s_data;
    assign m2_data      = s_data;
    assign m1_valid     = s_valid && m2_ready;
    assign m2_valid     = s_valid && m1_ready;
    assign s_ready      = m1_ready && m2_ready;

endmodule
