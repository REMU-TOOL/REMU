`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_encoder_w #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    `AXI4_CUSTOM_W_SLAVE_IF     (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

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

    reg [63:0] reg_wdata;

    wire axi_wfire = axi_wvalid && axi_wready;
    wire data_fire = data_valid && data_ready;

    always @(posedge clk)
        if (rst)
            state <= STATE_IDLE;
        else
            state <= state_next;

    always @*
        case (state)
            STATE_IDLE:
                if (axi_wfire)
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

    assign axi_wready = state == STATE_IDLE;
    assign data_valid = state == STATE_HEAD ||
                        state == STATE_DATA_1 ||
                        state == STATE_DATA_2;

    always @(posedge clk)
        if (axi_wfire)
            reg_wdata <= axi_wdata;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (axi_wfire)
                    data <= {{16-(DATA_WIDTH/8){1'b0}}, axi_wstrb, 15'd0, axi_wlast};
            STATE_HEAD:
                if (data_fire)
                    data <= reg_wdata[31:0];
            STATE_DATA_1:
                if (data_fire)
                    data <= reg_wdata[63:32];
        endcase

    assign idle         = state == STATE_IDLE;

endmodule

`default_nettype wire
