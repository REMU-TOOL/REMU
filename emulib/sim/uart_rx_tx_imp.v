`timescale 1ns / 1ps

`include "axi.vh"

module EmuUartRxTxImp (
    input  wire         clk,

    input  wire         tx_valid,
    input  wire [7:0]   tx_ch,
    output wire         rx_valid,
    output wire [7:0]   rx_ch,

    (* remu_signal *)
    input  wire         _rx_toggle,
    (* remu_signal *)
    input  wire [7:0]   _rx_ch
);

    always @(posedge clk) begin
        if (tx_valid)
            $write("%c", tx_ch);
    end

    reg _rx_toggle_pre;

    always @(posedge clk)
        _rx_toggle_pre <= _rx_toggle;

    assign rx_valid = _rx_toggle && !_rx_toggle_pre;
    assign rx_ch = _rx_ch;

endmodule
