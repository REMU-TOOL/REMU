`timescale 1ns / 1ps
`default_nettype none

`include "axi_custom.vh"

module emulib_rammodel_decoder_a #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 data_valid,
    output wire                 data_ready,
    input  wire [31:0]          data,

    `AXI4_CUSTOM_A_MASTER_IF    (axi, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    output wire                 idle

);

    localparam ADDR_32 = ADDR_WIDTH <= 32;

    localparam [1:0]
        STATE_IDLE      = 2'd0,
        STATE_HEAD      = 2'd1,
        STATE_ADDR_1    = 2'd2,
        STATE_ADDR_2    = 2'd3;

    reg [1:0] state, state_next;

    reg         reg_awrite;
    reg [63:0]  reg_aaddr;
    reg [15:0]  reg_aid;
    reg [7:0]   reg_alen;
    reg [2:0]   reg_asize;
    reg [1:0]   reg_aburst;

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
                if (data_fire)
                    state_next = STATE_HEAD;
                else
                    state_next = STATE_IDLE;
            STATE_HEAD:
                if (data_fire)
                    state_next = STATE_ADDR_1;
                else
                    state_next = STATE_HEAD;
            STATE_ADDR_1:
                if (ADDR_32 ? axi_afire : data_fire)
                    state_next = ADDR_32 ? STATE_IDLE : STATE_ADDR_2;
                else
                    state_next = STATE_ADDR_1;
            STATE_ADDR_2:
                if (axi_afire)
                    state_next = STATE_IDLE;
                else
                    state_next = STATE_ADDR_2;
            default:
                state_next = STATE_IDLE;
        endcase

    assign data_ready = state == STATE_IDLE ||
                        state == STATE_HEAD ||
                        state == STATE_ADDR_1 && !ADDR_32;
    assign axi_avalid = ADDR_32 ? state == STATE_ADDR_1 : state == STATE_ADDR_2;

    always @(posedge clk)
        case (state)
            STATE_IDLE:
                if (data_fire) begin
                    reg_aid     <= data[31:16];
                    reg_alen    <= data[15:8];
                    reg_asize   <= data[7:5];
                    reg_aburst  <= data[4:3];
                    reg_awrite  <= data[0];
                end
            STATE_HEAD:
                if (data_fire)
                    reg_aaddr[31:0] <= data;
            STATE_ADDR_1:
                if (data_fire)
                    reg_aaddr[63:32] <= data;
        endcase

    assign axi_awrite   = reg_awrite;
    assign axi_aaddr    = reg_aaddr[ADDR_WIDTH-1:0];
    assign axi_aid      = reg_aid[ID_WIDTH-1:0];
    assign axi_alen     = reg_alen;
    assign axi_asize    = reg_asize;
    assign axi_aburst   = reg_aburst;

    assign idle         = state == STATE_IDLE;

endmodule

`default_nettype wire
