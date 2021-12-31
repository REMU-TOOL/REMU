`timescale 1 ns / 1 ps

module trigger(
    input trigger
);

    (* keep, emu_intf_port = "dut_trig" *)
    wire _trig;

    assign _trig = trigger;

endmodule
