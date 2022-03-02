`resetall
`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_mux #(
    parameter   NUM_S       = 1,
    parameter   NUM_M       = 1,
    parameter   DATA_WIDTH  = 1
)(
    input  wire [NUM_S-1:0]             s_valid,
    output wire [NUM_S-1:0]             s_ready,
    input  wire [DATA_WIDTH*NUM_S-1:0]  s_data,
    input  wire [NUM_S-1:0]             s_sel,

    output wire [NUM_M-1:0]             m_valid,
    input  wire [NUM_M-1:0]             m_ready,
    output wire [DATA_WIDTH*NUM_M-1:0]  m_data,
    input  wire [NUM_S-1:0]             m_sel
);

    wire valid = |(s_valid & s_sel);
    wire ready = |(m_ready & m_sel);

    reg [DATA_WIDTH-1:0] data;
    integer i;

    always @* begin
        data = {DATA_WIDTH{1'b0}};
        for (i = 0; i < NUM_S; i = i + 1)
            if (s_sel[i])
                data = s_data[i * DATA_WIDTH +: DATA_WIDTH];
    end

    assign m_data  = {NUM_M{data}};
    assign m_valid = {NUM_M{valid}} & m_sel;
    assign s_ready = {NUM_S{ready}} & s_sel;

endmodule

`resetall
