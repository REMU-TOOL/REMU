`timescale 1ns / 1ps

module emulib_ready_valid_fork #(
    parameter   BRANCHES    = 2
)(
    input  wire                 i_valid,
    output wire                 i_ready,

    output reg  [BRANCHES-1:0]  o_valid,
    input  wire [BRANCHES-1:0]  o_ready
);

    integer i, j;

    always @* begin
        o_valid = {BRANCHES{i_valid}};
        for (i = 0; i < BRANCHES; i = i + 1)
            for (j = 0; j < BRANCHES; j = j + 1)
                if (i != j)
                    o_valid[i] = o_valid[i] && o_ready[j];
    end

    assign i_ready = &o_ready;

endmodule
