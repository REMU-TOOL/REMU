`timescale 1ns / 1ps

`include "axi.vh"

(* __emu_model_imp *)
module EmuTracePortImp #(
    parameter   DATA_WIDTH  = 1
)(
    input  wire                     clk,

    // Data Channel

    (* __emu_channel_name = "data"*)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "data" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_data_valid" *)
    (* __emu_channel_ready = "tk_data_ready" *)

    input  wire                     tk_data_valid,
    output wire                     tk_data_ready,

    input  wire [DATA_WIDTH-1:0]    data,

    (* __emu_trace_port_name = "trace" *)
    (* __emu_trace_port_valid = "trace_valid" *)
    (* __emu_trace_port_ready = "trace_ready" *)
    (* __emu_trace_port_data = "trace_data" *)

    output wire                     trace_valid,
    input  wire                     trace_ready,
    output wire [DATA_WIDTH-1:0]    trace_data
);

    assign trace_valid = tk_data_valid;
    assign tk_data_ready = trace_ready;
    assign trace_data = data;

endmodule
