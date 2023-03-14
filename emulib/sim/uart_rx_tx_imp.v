`timescale 1ns / 1ps

`include "axi.vh"

module EmuUartRxTxImp (
    input  wire         clk,

    input  wire         tx_valid,
    input  wire [7:0]   tx_ch,
    output wire         rx_valid,
    output wire [7:0]   rx_ch,

    (* remu_signal, remu_trigger *)
    output wire         _tx_valid,
    (* remu_signal *)
    output wire [7:0]   _tx_ch,
    (* remu_signal *)
    input  wire         _rx_valid,
    (* remu_signal *)
    input  wire [7:0]   _rx_ch
);

    assign _tx_valid = tx_valid;
    assign _tx_ch = tx_ch;
    assign rx_valid = _rx_valid;
    assign rx_ch = _rx_ch;

    always @(posedge clk) begin
        if (tx_valid)
            $write("%c", tx_ch);
    end

endmodule
