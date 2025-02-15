`timescale 1ns / 1ps

module emulib_serializer #(
    parameter   DATA_WIDTH  = 2
)(
    input   wire                    clk,
    input   wire                    rst,

    input   wire                    i_valid,
    input   wire [DATA_WIDTH-1:0]   i_data,
    output  wire                    i_ready,
    output  wire                    o_valid,
    output  wire                    o_data,
    input   wire                    o_ready
);
    initial begin
        if (DATA_WIDTH <= 1) begin
            $display("ERROR: DATA_WIDTH(%d) should be greater than 1", DATA_WIDTH);
            $finish;
        end
    end

    localparam CNT_BITS = $clog2(DATA_WIDTH + 1);
    reg [DATA_WIDTH-1:0] data_reg;
    reg [CNT_BITS-1:0] cnt = 0;

    assign i_ready  = cnt == 0;
    assign o_valid  = !i_ready;
    assign o_data   = data_reg[0];

    always @(posedge clk) begin
        if (i_valid && !o_valid)
            data_reg <= i_data;
        else if (o_valid && o_ready)
            data_reg <= data_reg >> 1;
    end

    always @(posedge clk) begin
        if (rst)
            cnt <= 0;
        else if (i_valid && i_ready)
            cnt <= DATA_WIDTH;
        else if (o_valid && o_ready)
            cnt <= cnt - 1;
    end

endmodule
