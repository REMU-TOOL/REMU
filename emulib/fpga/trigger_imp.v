`timescale 1 ns / 1 ps

(* keep, __emu_model_imp = "trigger" *)
module EmuTriggerImp #(
    parameter DESC = "<empty>"
)(
    input wire trigger,
    (* __emu_user_trig, __emu_user_trig_desc = DESC *)
    output wire user_trig
);

    assign user_trig = trigger;

endmodule
