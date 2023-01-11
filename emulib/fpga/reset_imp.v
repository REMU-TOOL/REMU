`timescale 1 ns / 1 ps

(* keep, __emu_model_imp *)
module EmuResetImp (
    output wire reset,
    (* __emu_user_rst *)
    input wire user_rst
);

    assign reset = user_rst;

endmodule
