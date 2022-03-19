`resetall
`timescale 1 ns / 1 ps
`default_nettype none

(* keep, __emu_directive = {
    "extern dut_trig;"
} *)

module EmuTrigger(
    input wire trigger,

    output wire dut_trig
);

    assign dut_trig = trigger;

endmodule

`resetall
