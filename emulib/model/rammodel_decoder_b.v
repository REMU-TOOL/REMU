`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_decoder_b #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 data_valid,
    output wire                 data_ready,
    input  wire [31:0]          data,

    `AXI4_CUSTOM_B_MASTER_IF    (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 idle

);

    localparam [0:0]
        STATE_IDLE      = 1'd0,
        STATE_HEAD      = 1'd1;

    reg [0:0] state, state_next;

    reg [15:0]  reg_bid;

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
                if (data_fire)
                    state_next = STATE_HEAD;
                else
                    state_next = STATE_IDLE;
            STATE_HEAD:
                if (axi_bfire)
                    state_next = STATE_IDLE;
                else
                    state_next = STATE_HEAD;
            default:
                state_next = STATE_IDLE;
        endcase

    assign data_ready = state == STATE_IDLE;
    assign axi_bvalid = state == STATE_HEAD;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (data_fire) begin
                    reg_bid     <= data[31:16];
                end
        endcase

    assign axi_bid      = reg_bid[ID_WIDTH-1:0];

    assign idle         = state == STATE_IDLE;

endmodule

`resetall
