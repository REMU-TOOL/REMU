`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_mux #(
    parameter   NUM_I       = 1,
    parameter   NUM_O       = 1,
    parameter   DATA_WIDTH  = 1
)(
    input  wire [NUM_I-1:0]             i_valid,
    output wire [NUM_I-1:0]             i_ready,
    input  wire [DATA_WIDTH*NUM_I-1:0]  i_data,
    input  wire [NUM_I-1:0]             i_sel,

    output wire [NUM_O-1:0]             o_valid,
    input  wire [NUM_O-1:0]             o_ready,
    output wire [DATA_WIDTH*NUM_O-1:0]  o_data,
    input  wire [NUM_O-1:0]             o_sel
);

    wire valid = |(s_valid & s_sel);
    wire ready = |(m_ready & m_sel);

    reg [DATA_WIDTH-1:0] data;
    integer i;

    always @* begin
        data = {DATA_WIDTH{1'b0}};
        for (i = 0; i < NUM_I; i = i + 1)
            if (s_sel[i])
                data = s_data[i * DATA_WIDTH +: DATA_WIDTH];
    end

    assign m_data  = {NUM_O{data}};
    assign m_valid = {NUM_O{valid}} & m_sel;
    assign s_ready = {NUM_I{ready}} & s_sel;

endmodule

`default_nettype wire
