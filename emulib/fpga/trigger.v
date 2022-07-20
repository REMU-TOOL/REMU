`timescale 1 ns / 1 ps
`default_nettype none

(* keep, noblackbox *)
module EmuTrigger #(
    parameter DESC = "<empty>"
)(
    (* __emu_user_trig, __emu_user_trig_desc = DESC *)
    input wire trigger
);

endmodule

`default_nettype wire
