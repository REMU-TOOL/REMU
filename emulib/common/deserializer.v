`timescale 1ns / 1ps

module emulib_deserializer #(
    parameter   DATA_WIDTH  = 1
)(
    input   wire                    clk,
    input   wire                    rst,

    input   wire                    i_valid,
    input   wire                    i_data,
    output  wire                    i_ready,
    output  wire                    o_valid,
    output  reg  [DATA_WIDTH-1:0]   o_data,
    input   wire                    o_ready
);

    localparam CNT_BITS = $clog2(DATA_WIDTH + 1);
    reg [CNT_BITS-1:0] cnt;

    assign o_valid  = cnt == DATA_WIDTH;
    assign i_ready  = !o_valid;

    always @(posedge clk) begin
        if (i_valid && i_ready)
            o_data <= {i_data, o_data[DATA_WIDTH-1:1]};
    end

    always @(posedge clk) begin
        if (rst || o_valid && o_ready)
            cnt <= 0;
        else if (i_valid && i_ready)
            cnt <= cnt + 1;
    end

endmodule
