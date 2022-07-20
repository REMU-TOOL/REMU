`timescale 1ns / 1ps
`default_nettype none

(* keep, __emu_model_imp *)
module EmuPutChar (

    (* __emu_model_common_port = "mdl_clk" *)
    input  wire         mdl_clk,
    (* __emu_model_common_port = "mdl_rst" *)
    input  wire         mdl_rst,

    input  wire         clk,

    // Reset Channel

    (* __emu_model_channel_name = "rst"*)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "rst" *)
    (* __emu_model_channel_valid = "tk_rst_valid" *)
    (* __emu_model_channel_ready = "tk_rst_ready" *)

    input  wire         tk_rst_valid,
    output wire         tk_rst_ready,

    input  wire         rst,

    // Data Channel

    (* __emu_model_channel_name = "data"*)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "valid data" *)
    (* __emu_model_channel_valid = "tk_data_valid" *)
    (* __emu_model_channel_ready = "tk_data_ready" *)

    input  wire         tk_data_valid,
    output wire         tk_data_ready,

    input  wire         valid,
    input  wire [7:0]   data,

    (* __emu_model_common_port = "putchar_valid" *)
    output wire         putchar_valid,
    (* __emu_model_common_port = "putchar_ready" *)
    input  wire         putchar_ready,
    (* __emu_model_common_port = "putchar_data" *)
    output wire [7:0]   putchar_data

);

    wire fifo_clear;

    reset_token_handler resetter (
        .mdl_clk        (mdl_clk),
        .mdl_rst        (mdl_rst),
        .tk_rst_valid   (tk_rst_valid),
        .tk_rst_ready   (tk_rst_ready),
        .tk_rst         (rst),
        .allow_rst      (1'b1),
        .rst_out        (fifo_clear)
    );

    emulib_ready_valid_fifo #(
        .WIDTH      (8),
        .DEPTH      (16)
    ) char_fifo (
        .clk        (mdl_clk),
        .rst        (mdl_rst || fifo_clear),
        .ivalid     (tk_data_valid && valid),
        .iready     (tk_data_ready),
        .idata      (data),
        .ovalid     (putchar_valid),
        .oready     (putchar_ready),
        .odata      (putchar_data)
    );

endmodule

`default_nettype wire
