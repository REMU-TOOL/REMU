`timescale 1 ns / 1 ps
`default_nettype none

module reset #(
    parameter DURATION_NS = 20
)
(
    output reset
);

    (* keep, emu_intf_port = "dut_rst" *)
    wire _rst;

    assign reset = _rst;

endmodule
