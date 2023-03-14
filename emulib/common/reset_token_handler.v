`timescale 1ns / 1ps

module reset_token_handler (

    input  wire     mdl_clk,
    input  wire     mdl_rst,

    input  wire     tk_rst_valid,
    output wire     tk_rst_ready,
    input  wire     tk_rst,

    input  wire     allow_rst,
    output reg      rst_out = 1'b0

);

    localparam [1:0]
        IDLE    = 2'd0,
        FIRE    = 2'd1,
        DONE    = 2'd2;

    reg [1:0] state = IDLE, state_next;

    always @(posedge mdl_clk)
        if (mdl_rst)
            state <= IDLE;
        else
            state <= state_next;

    always @*
        case (state)
        IDLE:
            if (tk_rst_valid && tk_rst && allow_rst)
                state_next = FIRE;
            else
                state_next = IDLE;
        FIRE:
            state_next = DONE;
        DONE:
            if (tk_rst_valid && !tk_rst)
                state_next = IDLE;
            else
                state_next = DONE;
        default:
            state_next = IDLE;
        endcase

    always @(posedge mdl_clk) begin
        if (mdl_rst) begin
            rst_out <= 1'b0;
        end
        else begin
            rst_out <= 1'b0;
            case (state_next)
                FIRE:   rst_out <= 1'b1;
            endcase
        end
    end

    assign tk_rst_ready = state == DONE || !tk_rst;

endmodule
