`timescale 1 ns / 1 ps

module EmuTrigger #(
    parameter DESC = "<empty>"
)(
    (* keep *) input wire trigger
);

    EmuTriggerImp #(
        .DESC(DESC)
    ) imp (
        .trigger(trigger)
    );

endmodule
