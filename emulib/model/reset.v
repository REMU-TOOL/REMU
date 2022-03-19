`resetall
`timescale 1 ns / 1 ps
`default_nettype none

(* keep, __emu_directive = {
    "extern dut_rst;"
} *)

module EmuReset #(
    parameter DURATION_NS = 20
)
(
    output wire reset,

    input wire dut_rst
);

    assign reset = dut_rst;

endmodule

`resetall
