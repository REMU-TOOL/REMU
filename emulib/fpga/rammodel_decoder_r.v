`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_decoder_r #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 data_valid,
    output wire                 data_ready,
    input  wire [31:0]          data,

    `AXI4_CUSTOM_R_MASTER_IF    (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 idle

);

    localparam DATA_32 = DATA_WIDTH <= 32;

    localparam [1:0]
        STATE_IDLE      = 2'd0,
        STATE_HEAD      = 2'd1,
        STATE_DATA_1    = 2'd2,
        STATE_DATA_2    = 2'd3;

    reg [1:0] state, state_next;

    reg [63:0]  reg_rdata;
    reg [15:0]  reg_rid;
    reg         reg_rlast;

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
                if (data_fire)
                    state_next = STATE_HEAD;
                else
                    state_next = STATE_IDLE;
            STATE_HEAD:
                if (data_fire)
                    state_next = STATE_DATA_1;
                else
                    state_next = STATE_HEAD;
            STATE_DATA_1:
                if (DATA_32 ? axi_rfire : data_fire)
                    state_next = DATA_32 ? STATE_IDLE : STATE_DATA_2;
                else
                    state_next = STATE_DATA_1;
            STATE_DATA_2:
                if (axi_rfire)
                    state_next = STATE_IDLE;
                else
                    state_next = STATE_DATA_2;
            default:
                state_next = STATE_IDLE;
        endcase

    assign data_ready = state == STATE_IDLE ||
                        state == STATE_HEAD ||
                        state == STATE_DATA_1 && !DATA_32;
    assign axi_rvalid = DATA_32 ? state == STATE_DATA_1 : state == STATE_DATA_2;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (data_fire) begin
                    reg_rid     <= data[31:16];
                    reg_rlast   <= data[0];
                end
            STATE_HEAD:
                if (data_fire)
                    reg_rdata[31:0] <= data;
            STATE_DATA_1:
                if (data_fire)
                    reg_rdata[63:32] <= data;
        endcase

    assign axi_rdata    = reg_rdata[DATA_WIDTH-1:0];
    assign axi_rid      = reg_rid[ID_WIDTH-1:0];
    assign axi_rlast    = reg_rlast;

    assign idle         = state == STATE_IDLE;

endmodule

`default_nettype wire
