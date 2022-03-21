`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_arb #(
    parameter   NUM_S       = 1,
    parameter   DATA_WIDTH  = 1
)(
    input  wire [NUM_S-1:0]             s_valid,
    output wire [NUM_S-1:0]             s_ready,
    input  wire [DATA_WIDTH*NUM_S-1:0]  s_data,

    output wire                         m_valid,
    input  wire                         m_ready,
    output reg  [DATA_WIDTH-1:0]        m_data,
    output reg  [NUM_S-1:0]             m_sel
);

    integer i;

    always @* begin
        m_sel = {NUM_S{1'b0}};
        m_data = {DATA_WIDTH{1'b0}};
        for (i = 0; i < NUM_S; i = i + 1) begin
            if (s_valid[i]) begin
                m_sel = {{(NUM_S-1){1'b0}}, 1'b1} << i;
                m_data = s_data[i * DATA_WIDTH +: DATA_WIDTH];
            end
        end
    end

    assign s_ready = {NUM_S{m_ready}} & m_sel;
    assign m_valid = |s_valid;

endmodule

`default_nettype wire
