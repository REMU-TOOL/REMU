`timescale 1 ns / 1 ps
`default_nettype none

(* keep *)
module EmuTrigger #(
    parameter DESC = "<empty>"
)(
    input wire trigger
);

    (* __emu_user_trig, __emu_user_trig_desc = DESC *)
    wire dut_trig;
    assign dut_trig = trigger;

endmodule

`default_nettype wire
