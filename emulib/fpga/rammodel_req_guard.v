`timescale 1ns / 1ps

// force all requests be sent after the previous one is completed

module emulib_rammodel_req_guard #(
    parameter   ADDR_WIDTH      = 32,
    parameter   ID_WIDTH        = 4
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                     awrite,
    input  wire [ADDR_WIDTH-1:0]    aaddr,
    input  wire [7:0]               alen,
    input  wire [2:0]               asize,
    input  wire [1:0]               aburst,

    input  wire                     afire,
    input  wire                     bfire,
    input  wire                     rfire,

    output wire                     allow_req
);

    reg in_flight;

    always @(posedge clk) begin
        if (rst)
            in_flight <= 1'b0;
        else if (afire)
            in_flight <= 1'b1;
        else if (bfire || rfire)
            in_flight <= 1'b0;
    end

    assign allow_req = !in_flight;

endmodule
