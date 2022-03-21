`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_decoder_w #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 data_valid,
    output wire                 data_ready,
    input  wire [31:0]          data,

    `AXI4_CUSTOM_W_MASTER_IF    (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 idle

);

    localparam DATA_32 = DATA_WIDTH <= 32;

    localparam [1:0]
        STATE_IDLE      = 2'd0,
        STATE_HEAD      = 2'd1,
        STATE_DATA_1    = 2'd2,
        STATE_DATA_2    = 2'd3;

    reg [1:0] state, state_next;

    reg [63:0]  reg_wdata;
    reg [7:0]   reg_wstrb;
    reg         reg_wlast;

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
                if (DATA_32 ? axi_wfire : data_fire)
                    state_next = DATA_32 ? STATE_IDLE : STATE_DATA_2;
                else
                    state_next = STATE_DATA_1;
            STATE_DATA_2:
                if (axi_wfire)
                    state_next = STATE_IDLE;
                else
                    state_next = STATE_DATA_2;
            default:
                state_next = STATE_IDLE;
        endcase

    assign data_ready = state == STATE_IDLE ||
                        state == STATE_HEAD ||
                        state == STATE_DATA_1 && !DATA_32;
    assign axi_wvalid = DATA_32 ? state == STATE_DATA_1 : state == STATE_DATA_2;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (data_fire) begin
                    reg_wstrb   <= data[23:16];
                    reg_wlast   <= data[0];
                end
            STATE_HEAD:
                if (data_fire)
                    reg_wdata[31:0] <= data;
            STATE_DATA_1:
                if (data_fire)
                    reg_wdata[63:32] <= data;
        endcase

    assign axi_wdata    = reg_wdata[DATA_WIDTH-1:0];
    assign axi_wstrb    = reg_wstrb[DATA_WIDTH/8-1:0];
    assign axi_wlast    = reg_wlast;

    assign idle         = state == STATE_IDLE;

endmodule

`default_nettype wire
