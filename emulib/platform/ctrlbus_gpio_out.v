`timescale 1ns / 1ps

module ctrlbus_gpio_out #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 32,
    parameter   NREGS           = 1,
    parameter   REG_WIDTH_LIST  = {32}
)(
    input                                   clk,
    input                                   rst,

    input  wire                             ctrl_wen,
    input  wire [ADDR_WIDTH-1:0]            ctrl_waddr,
    input  wire [DATA_WIDTH-1:0]            ctrl_wdata,
    input  wire                             ctrl_ren,
    input  wire [ADDR_WIDTH-1:0]            ctrl_raddr,
    output wire [DATA_WIDTH-1:0]            ctrl_rdata,

    output wire [DATA_WIDTH*NREGS-1:0]      gpio_out
);

    genvar i;

    for (i=0; i<NREGS; i=i+1) begin
        localparam WIDTH = REG_WIDTH_LIST[i*32+:32];
        reg [WIDTH-1:0] r;

        always @(posedge clk) begin
            if (rst)
                r <= {WIDTH{1'b0}};
            else if (ctrl_wen && ctrl_waddr[ADDR_WIDTH-1:2] == i)
                r <= ctrl_wdata[WIDTH-1:0];
        end

        assign gpio_out[i*32+:32] = {{32-WIDTH{1'b0}}, r};
    end

    assign ctrl_rdata = gpio_out[ctrl_raddr[ADDR_WIDTH-1:2]*32+:32];

endmodule
