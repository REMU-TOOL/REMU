`timescale 1ns / 1ps

module emulib_ready_valid_gate #(
    parameter   DECOUPLE_S  = 1,
    parameter   DECOUPLE_M  = 1
)(
    input  wire     i_valid,
    output wire     i_ready,

    output wire     o_valid,
    input  wire     o_ready,

    input  wire     enable
);

    if (DECOUPLE_S)
        assign i_ready = o_ready && enable;
    else
        assign i_ready = o_ready;

    if (DECOUPLE_M)
        assign o_valid = i_valid && enable;
    else
        assign o_valid = i_valid;

endmodule
