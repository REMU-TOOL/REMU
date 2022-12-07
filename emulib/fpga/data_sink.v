`timescale 1ns / 1ps

(* keep, __emu_model_imp *)
module EmuDataSink #(
    parameter DATA_WIDTH = 1,
    parameter FIFO_DEPTH = 16
)(

    (* __emu_model_common_port = "mdl_clk" *)
    input  wire                     mdl_clk,
    (* __emu_model_common_port = "mdl_rst" *)
    input  wire                     mdl_rst,

    input  wire                     clk,

    (* __emu_model_channel_name = "write"*)
    (* __emu_model_channel_direction = "in" *)
    (* __emu_model_channel_payload = "wen wdata" *)
    (* __emu_model_channel_valid = "tk_write_valid" *)
    (* __emu_model_channel_ready = "tk_write_ready" *)

    input  wire                     tk_write_valid,
    output wire                     tk_write_ready,

    input  wire                     wen,
    input  wire [DATA_WIDTH-1:0]    wdata,

    (* __emu_fifo_port_name = "sink" *)
    (* __emu_fifo_port_type = "sink" *)
    (* __emu_fifo_port_enable = "sink_ren" *)
    (* __emu_fifo_port_data = "sink_rdata" *)
    (* __emu_fifo_port_flag = "sink_rempty" *)

    input  wire                     sink_ren,
    output wire [DATA_WIDTH-1:0]    sink_rdata,
    output wire                     sink_rempty

);

    wire wfull;

    (* __emu_no_scanchain *)
    emulib_fifo #(
        .WIDTH      (DATA_WIDTH),
        .DEPTH      (FIFO_DEPTH)
    ) fifo (
        .clk        (mdl_clk),
        .rst        (mdl_rst),
        .winc       (tk_write_valid && wen),
        .wdata      (wdata),
        .wfull      (wfull),
        .rinc       (sink_ren),
        .rdata      (sink_rdata),
        .rempty     (sink_rempty)
    );

    assign tk_write_ready = !wfull;

endmodule
