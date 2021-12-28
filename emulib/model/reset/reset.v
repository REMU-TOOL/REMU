`timescale 1 ns / 1 ps

module reset #(
    parameter DURATION_NS = 20
)
(
    output reset
);

    (* keep, emu_internal_sig = "DUT_RST" *)
    wire _rst;

    assign reset = _rst;

endmodule
