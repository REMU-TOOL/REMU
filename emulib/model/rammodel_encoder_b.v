`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_encoder_b #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    `AXI4_CUSTOM_B_SLAVE_IF     (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 data_valid,
    input  wire                 data_ready,
    output reg  [31:0]          data,

    output wire                 idle

);

    localparam [0:0]
        STATE_IDLE      = 1'd0,
        STATE_HEAD      = 1'd1;

    reg [0:0] state, state_next;

    wire axi_bfire = axi_bvalid && axi_bready;
    wire data_fire = data_valid && data_ready;

    always @(posedge clk)
        if (rst)
            state <= STATE_IDLE;
        else
            state <= state_next;

    always @*
        case (state)
            STATE_IDLE:
                if (axi_bfire)
                    state_next = STATE_HEAD;
                else
                    state_next = STATE_IDLE;
            STATE_HEAD:
                if (data_fire)
                    state_next = STATE_IDLE;
                else
                    state_next = STATE_HEAD;
            default:
                state_next = STATE_IDLE;
        endcase

    assign axi_bready = state == STATE_IDLE;
    assign data_valid = state == STATE_HEAD;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (axi_bfire)
                    data <= {{16-ID_WIDTH{1'b0}}, axi_bid, 16'd0};
        endcase

    assign idle         = state == STATE_IDLE;

endmodule

`default_nettype wire
