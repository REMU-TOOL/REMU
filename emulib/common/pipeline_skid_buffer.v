`timescale 1ns / 1ps

module emulib_pipeline_skid_buffer #(
    parameter   DATA_WIDTH      = 1
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                     i_valid,
    input  wire [DATA_WIDTH-1:0]    i_data,
    output reg                      i_ready,

    output reg                      o_valid,
    output reg  [DATA_WIDTH-1:0]    o_data,
    input  wire                     o_ready
);

    reg [DATA_WIDTH-1:0] data_buf;

    always @(posedge clk) begin
        if (rst)
            o_valid <= 1'b0;
        else if (!i_ready || i_valid)
            o_valid <= 1'b1;
        else if (o_ready)
            o_valid <= 1'b0;
    end

    always @(posedge clk) begin
        if (rst)
            i_ready <= 1'b1;
        else if (!o_valid || o_ready)
            i_ready <= 1'b1;
        else if (i_valid)
            i_ready <= 1'b0;
    end

    always @(posedge clk) if (!o_valid || o_ready) o_data <= i_ready ? i_data : data_buf;
    always @(posedge clk) if (i_ready) data_buf <= i_data;

endmodule
