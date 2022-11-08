`timescale 1 ns / 1 ps

(* keep *)
module EmuReset (
    output wire reset,
    (* __emu_user_rst *)
    input wire user_rst
);

    assign reset = user_rst;

endmodule
