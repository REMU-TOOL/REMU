`resetall
`timescale 1ns / 1ps
`default_nettype none

module rst_down_gen (
    input  wire     clk,
    input  wire     rst,
    input  wire     dut_rst,
    input  wire     stall,
    output wire     stall_gen,
    output wire     down_req,
    input  wire     down_stat,
    output wire     rst_gen
);

    localparam [1:0]
        STATE_INIT  = 0,
        STATE_DOWN  = 1,
        STATE_WAIT  = 2;

    reg [1:0] state, state_next;

    always @(posedge clk) begin
        if (rst)
            state <= STATE_INIT;
        else
            state <= state_next;
    end

    always @* begin
        case (state)
            STATE_INIT: state_next = dut_rst && !stall ? STATE_DOWN : STATE_INIT;
            STATE_DOWN: state_next = down_stat ? STATE_WAIT : STATE_DOWN;
            STATE_WAIT:  state_next = !dut_rst && !stall ? STATE_INIT : STATE_WAIT;
            default:    state_next = STATE_INIT;
        endcase
    end

    assign stall_gen    = state == STATE_DOWN;
    assign down_req     = state == STATE_DOWN;
    assign rst_gen      = state == STATE_WAIT;

endmodule

`resetall
