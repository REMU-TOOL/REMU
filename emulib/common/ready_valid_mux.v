`timescale 1ns / 1ps

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

    wire valid = |(i_valid & i_sel);
    wire ready = |(o_ready & o_sel);

    reg [DATA_WIDTH-1:0] data;
    integer i;

    always @* begin
        data = {DATA_WIDTH{1'b0}};
        for (i = 0; i < NUM_I; i = i + 1)
            if (i_sel[i])
                data = i_data[i * DATA_WIDTH +: DATA_WIDTH];
    end

    assign o_data  = {NUM_O{data}};
    assign o_valid = {NUM_O{valid}} & o_sel;
    assign i_ready = {NUM_I{ready}} & i_sel;

endmodule
