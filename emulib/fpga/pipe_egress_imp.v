`timescale 1ns / 1ps

(* keep, __emu_model_imp = "pipe_egress" *)
module emulib_egress_pipe_imp #(
    parameter DATA_WIDTH = 1
)(
    input  wire                     clk,
    input  wire                     valid,
    input  wire [DATA_WIDTH-1:0]    data,

    (* __emu_model_channel_name = "data" *)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "valid data" *)
    (* __emu_model_channel_valid = "tk_data_valid" *)
    (* __emu_model_channel_ready = "tk_data_ready" *)

    output wire                     tk_data_valid,
    input  wire                     tk_data_ready,

    (* __emu_pipe_name = "stream" *)
    (* __emu_pipe_direction = "out" *)
    (* __emu_pipe_type = "pio" *)

    output wire                     stream_valid,
    output wire [DATA_WIDTH-1:0]    stream_data,
    input  wire                     stream_ready
);

    assign stream_valid = tk_data_valid && valid;
    assign tk_data_ready = stream_ready || !valid;

    assign stream_data = data;

endmodule
