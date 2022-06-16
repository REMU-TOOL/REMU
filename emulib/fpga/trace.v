`timescale 1ns / 1ps
`default_nettype none

(* keep, __emu_directive = {
    "extern host_clk;",
    "extern host_rst;",
    "extern target_fire;",
    "extern stall;",
    "extern -rename trace_*;"
} *)

module EmuTrace #(
    parameter   DATA_WIDTH  = 64
)(
    input  wire                     clk,
    input  wire                     valid,
    input  wire [DATA_WIDTH-1:0]    data,

    input  wire                     host_clk,
    input  wire                     host_rst,
    input  wire                     target_fire,
    output wire                     stall,
    output wire                     trace_valid,
    input  wire                     trace_ready,
    output wire [DATA_WIDTH-1:0]    trace_data
);

    wire decoupled_valid = target_fire && valid;
    wire rs_ready;

    emulib_pipeline_skid_buffer #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_reg_slice (
        .clk        (host_clk),
        .rst        (host_rst),
        .i_valid    (decoupled_valid),
        .i_data     (data),
        .i_ready    (rs_ready),
        .o_valid    (trace_valid),
        .o_data     (trace_data),
        .o_ready    (trace_ready)
    );

    assign stall = valid && !rs_ready;

endmodule

`default_nettype wire
