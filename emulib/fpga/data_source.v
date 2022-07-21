`timescale 1ns / 1ps
`default_nettype none

(* keep, __emu_model_imp *)
module EmuDataSource #(
    parameter DATA_WIDTH = 1,
    parameter FIFO_DEPTH = 16
)(

    (* __emu_model_common_port = "mdl_clk" *)
    input  wire                     mdl_clk,
    (* __emu_model_common_port = "mdl_rst" *)
    input  wire                     mdl_rst,

    input  wire                     clk,

    (* __emu_model_channel_name = "read"*)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "ren" *)
    (* __emu_model_channel_valid = "tk_read_valid" *)
    (* __emu_model_channel_ready = "tk_read_ready" *)

    input  wire                     tk_read_valid,
    output wire                     tk_read_ready,

    input  wire                     ren,

    (* __emu_model_channel_name = "read_data"*)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "rdata" *)
    (* __emu_model_channel_valid = "tk_read_data_valid" *)
    (* __emu_model_channel_ready = "tk_read_data_ready" *)

    output wire                     tk_read_data_valid,
    input  wire                     tk_read_data_ready,

    output wire [DATA_WIDTH-1:0]    rdata,

    (* __emu_fifo_port_name = "sink" *)
    (* __emu_fifo_port_type = "write" *)
    (* __emu_fifo_port_enable = "sink_wen" *)
    (* __emu_fifo_port_data = "sink_wdata" *)
    (* __emu_fifo_port_flag = "sink_wfull" *)

    input  wire                     sink_wen,
    input  wire [DATA_WIDTH-1:0]    sink_wdata,
    output wire                     sink_wfull

);

    wire rempty;

    emulib_fifo #(
        .WIDTH      (DATA_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) fifo (
        .clk        (mdl_clk),
        .rst        (mdl_rst),
        .winc       (sink_wen),
        .wdata      (sink_wdata),
        .wfull      (sink_wfull),
        .rinc       (tk_read_valid && ren),
        .rdata      (rdata),
        .rempty     (rempty)
    );

    assign tk_read_ready = !rempty;
    assign tk_read_data_valid = 1'b1;

endmodule

`default_nettype wire
