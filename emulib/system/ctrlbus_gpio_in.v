`timescale 1ns / 1ps

module ctrlbus_gpio_in #(
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

    input  wire [DATA_WIDTH*NREGS-1:0]      gpio_in
);

    assign ctrl_rdata = gpio_in[ctrl_raddr[ADDR_WIDTH-1:2]*32+:32];

endmodule
