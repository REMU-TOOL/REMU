`resetall
`timescale 1 ns / 1 ps
`default_nettype none

module trigger(
    input wire trigger
);

    (* keep, emu_intf_port = "dut_trig" *)
    wire _trig;

    assign _trig = trigger;

endmodule

`resetall
