`timescale 1ns / 1ps

module emulib_ready_valid_join #(
    parameter   BRANCHES    = 2
)(
    input  wire [BRANCHES-1:0]  i_valid,
    output reg  [BRANCHES-1:0]  i_ready,

    output wire                 o_valid,
    input  wire                 o_ready
);

    integer i, j;

    always @* begin
        i_ready = {BRANCHES{o_ready}};
        for (i = 0; i < BRANCHES; i = i + 1)
            for (j = 0; j < BRANCHES; j = j + 1)
                if (i != j)
                    i_ready[i] = i_ready[i] && i_valid[j];
    end

    assign o_valid = &i_valid;

endmodule
