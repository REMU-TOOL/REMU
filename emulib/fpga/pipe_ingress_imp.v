`timescale 1ns / 1ps

(* keep, __emu_model_imp = "pipe_ingress" *)
module emulib_ingress_pipe_imp #(
    parameter DATA_WIDTH = 1
)(
    input  wire                     clk,
    input  wire                     enable,
    output wire                     valid,
    output wire [DATA_WIDTH-1:0]    data,

    (* __emu_model_channel_name = "enable" *)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "enable" *)
    (* __emu_model_channel_valid = "tk_enable_valid" *)
    (* __emu_model_channel_ready = "tk_enable_ready" *)

    input  wire                     tk_enable_valid,
    output wire                     tk_enable_ready,

    (* __emu_model_channel_name = "data" *)
    (* __emu_model_channel_direction = "out" *)
    (* __emu_model_channel_depends_on = "enable" *)
    (* __emu_model_channel_payload = "valid data" *)
    (* __emu_model_channel_valid = "tk_data_valid" *)
    (* __emu_model_channel_ready = "tk_data_ready" *)

    output wire                     tk_data_valid,
    input  wire                     tk_data_ready,

    (* __emu_pipe_name = "stream" *)
    (* __emu_pipe_direction = "in" *)
    (* __emu_pipe_type = "pio" *)

    input  wire                     stream_valid,
    input  wire [DATA_WIDTH-1:0]    stream_data,
    input  wire                     stream_empty,
    output wire                     stream_ready
);

    assign tk_enable_ready = tk_data_ready && (!enable || stream_valid);
    assign tk_data_valid = tk_enable_valid && (!enable || stream_valid);
    assign stream_ready = tk_enable_valid && enable && tk_data_ready;

    assign valid = enable && !stream_empty;
    assign data = stream_data;

endmodule
