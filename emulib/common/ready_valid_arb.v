`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_arb #(
    parameter   NUM_I       = 1,
    parameter   DATA_WIDTH  = 1
)(
    input  wire [NUM_I-1:0]             i_valid,
    output wire [NUM_I-1:0]             i_ready,
    input  wire [DATA_WIDTH*NUM_I-1:0]  i_data,

    output wire                         o_valid,
    input  wire                         o_ready,
    output reg  [DATA_WIDTH-1:0]        o_data,
    output reg  [NUM_I-1:0]             o_sel
);

    integer i;

    always @* begin
        o_sel = {NUM_I{1'b0}};
        o_data = {DATA_WIDTH{1'b0}};
        for (i = 0; i < NUM_I; i = i + 1) begin
            if (i_valid[i]) begin
                o_sel = {{(NUM_I-1){1'b0}}, 1'b1} << i;
                o_data = i_data[i * DATA_WIDTH +: DATA_WIDTH];
            end
        end
    end

    assign i_ready = {NUM_I{o_ready}} & o_sel;
    assign o_valid = |i_valid;

endmodule

`default_nettype wire
