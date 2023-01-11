`timescale 1ns / 1ps

(* keep, __emu_model_imp *)
module EmuClockImp (
    output wire clock,
    (* __emu_user_clk *)
    input wire user_clk
);

    assign clock = user_clk;

endmodule
