`timescale 1 ns / 1 ps
`default_nettype none

(* keep *)
module EmuTrigger #(
    parameter DESC = ""
)(
    input wire trigger
);

    (* __emu_user_trig *)
    wire dut_trig;
    assign dut_trig = trigger;

endmodule

`default_nettype wire
