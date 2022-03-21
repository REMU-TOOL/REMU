`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_encoder_r #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    `AXI4_CUSTOM_R_SLAVE_IF     (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 data_valid,
    input  wire                 data_ready,
    output reg  [31:0]          data,

    output wire                 idle

);

    localparam DATA_32 = DATA_WIDTH <= 32;

    localparam [1:0]
        STATE_IDLE      = 2'd0,
        STATE_HEAD      = 2'd1,
        STATE_DATA_1    = 2'd2,
        STATE_DATA_2    = 2'd3;

    reg [1:0] state, state_next;

    reg [63:0] reg_rdata;

    wire axi_rfire = axi_rvalid && axi_rready;
    wire data_fire = data_valid && data_ready;

    always @(posedge clk)
        if (rst)
            state <= STATE_IDLE;
        else
            state <= state_next;

    always @*
        case (state)
            STATE_IDLE:
                if (axi_rfire)
                    state_next = STATE_HEAD;
                else
                    state_next = STATE_IDLE;
            STATE_HEAD:
                if (data_fire)
                    state_next = STATE_DATA_1;
                else
                    state_next = STATE_HEAD;
            STATE_DATA_1:
                if (data_fire)
                    state_next = DATA_32 ? STATE_IDLE : STATE_DATA_2;
                else
                    state_next = STATE_DATA_1;
            STATE_DATA_2:
                if (data_fire)
                    state_next = STATE_IDLE;
                else
                    state_next = STATE_DATA_2;
            default:
                state_next = STATE_IDLE;
        endcase

    assign axi_rready = state == STATE_IDLE;
    assign data_valid = state == STATE_HEAD ||
                        state == STATE_DATA_1 ||
                        state == STATE_DATA_2;

    always @(posedge clk)
        if (axi_rfire)
            reg_rdata <= axi_rdata;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (axi_rfire)
                    data <= {{16-ID_WIDTH{1'b0}}, axi_rid, 15'd0, axi_rlast};
            STATE_HEAD:
                if (data_fire)
                    data <= reg_rdata[31:0];
            STATE_DATA_1:
                if (data_fire)
                    data <= reg_rdata[63:32];
        endcase

    assign idle         = state == STATE_IDLE;

endmodule

`default_nettype wire
