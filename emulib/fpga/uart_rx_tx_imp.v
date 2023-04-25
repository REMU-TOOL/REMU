`timescale 1ns / 1ps

`include "axi.vh"

(* __emu_model_imp *)
module EmuUartRxTxImp (
    (* __emu_common_port = "mdl_clk" *)
    input  wire                     mdl_clk,
    (* __emu_common_port = "mdl_rst" *)
    input  wire                     mdl_rst,

    input  wire         clk,

    (* __emu_channel_name = "tx"*)
    (* __emu_channel_direction = "in" *)
    (* __emu_channel_payload = "tx_*" *)
    (* __emu_channel_clock = "clk" *)
    (* __emu_channel_valid = "tk_tx_valid" *)
    (* __emu_channel_ready = "tk_tx_ready" *)

    input  wire                     tk_tx_valid,
    output wire                     tk_tx_ready,

    input  wire         tx_valid,
    input  wire [7:0]   tx_ch,

    output wire         rx_valid,
    output wire [7:0]   rx_ch,

    (* remu_signal *)
    input  wire         _rx_valid,
    (* remu_signal *)
    input  wire [7:0]   _rx_ch,

    (* __emu_trace_port_name = "uart_tx" *)
    (* __emu_trace_port_type = "uart_tx" *)
    (* __emu_trace_port_valid = "uart_tx_valid" *)
    (* __emu_trace_port_ready = "uart_tx_ready" *)
    (* __emu_trace_port_data = "uart_tx_data" *)

    output wire          uart_tx_valid,
    input  wire          uart_tx_ready,
    output wire [7:0]    uart_tx_data
);

    wire tx_fifo_valid;
    wire tx_fifo_ready;
    wire [7:0] tx_fifo_data;

    (* __emu_no_scanchain *)
    emulib_ready_valid_fifo #(
        .WIDTH  (8),
        .DEPTH  (16)
    ) tx_fifo (
        .clk    (mdl_clk),
        .rst    (mdl_rst),
        .ivalid (tx_fifo_valid),
        .iready (tx_fifo_ready),
        .idata  (tx_fifo_data),
        .ovalid (uart_tx_valid),
        .oready (uart_tx_ready),
        .odata  (uart_tx_data)
    );

    assign tx_fifo_valid = tk_tx_valid && tx_valid;
    assign tx_fifo_data = tx_ch;
    assign tk_tx_ready = tx_fifo_ready || !tx_valid;

    assign rx_valid = _rx_valid;
    assign rx_ch = _rx_ch;

endmodule
