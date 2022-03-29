`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_encoder_a #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    `AXI4_CUSTOM_A_SLAVE_IF     (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 data_valid,
    input  wire                 data_ready,
    output reg  [31:0]          data,

    output wire                 idle

);

    localparam ADDR_32 = ADDR_WIDTH <= 32;

    localparam [1:0]
        STATE_IDLE      = 2'd0,
        STATE_HEAD      = 2'd1,
        STATE_ADDR_1    = 2'd2,
        STATE_ADDR_2    = 2'd3;

    reg [1:0] state, state_next;

    reg [63:0] reg_aaddr;

    wire axi_afire = axi_avalid && axi_aready;
    wire data_fire = data_valid && data_ready;

    always @(posedge clk)
        if (rst)
            state <= STATE_IDLE;
        else
            state <= state_next;

    always @*
        case (state)
            STATE_IDLE:
                if (axi_afire)
                    state_next = STATE_HEAD;
                else
                    state_next = STATE_IDLE;
            STATE_HEAD:
                if (data_fire)
                    state_next = STATE_ADDR_1;
                else
                    state_next = STATE_HEAD;
            STATE_ADDR_1:
                if (data_fire)
                    state_next = ADDR_32 ? STATE_IDLE : STATE_ADDR_2;
                else
                    state_next = STATE_ADDR_1;
            STATE_ADDR_2:
                if (data_fire)
                    state_next = STATE_IDLE;
                else
                    state_next = STATE_ADDR_2;
            default:
                state_next = STATE_IDLE;
        endcase

    assign axi_aready = state == STATE_IDLE;
    assign data_valid = state == STATE_HEAD ||
                        state == STATE_ADDR_1 ||
                        state == STATE_ADDR_2;

    always @(posedge clk)
        if (axi_afire)
            reg_aaddr <= axi_aaddr;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (axi_afire)
                    data <= {{16-ID_WIDTH{1'b0}}, axi_aid, axi_alen, axi_asize, axi_aburst, 2'd0, axi_awrite};
            STATE_HEAD:
                if (data_fire)
                    data <= reg_aaddr[31:0];
            STATE_ADDR_1:
                if (data_fire)
                    data <= reg_aaddr[63:32];
        endcase

    assign idle         = state == STATE_IDLE;

endmodule

`default_nettype wire
