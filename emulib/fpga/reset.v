`timescale 1 ns / 1 ps
`default_nettype none

(* keep *)
module EmuReset (
    output wire reset
);

    (* __emu_user_rst *)
    wire dut_rst;
    assign reset = dut_rst;

endmodule

`default_nettype wire
