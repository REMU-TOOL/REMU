`timescale 1 ns / 1 ps

module trigger(
    input trigger
);

    (* keep, emu_internal_sig = "DUT_TRIG" *)
    wire _trig;

    assign _trig = trigger;

endmodule
