`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_join #(
    parameter   BRANCHES    = 2
)(
    input  wire [BRANCHES-1:0]  s_valid,
    output reg  [BRANCHES-1:0]  s_ready,

    output wire                 m_valid,
    input  wire                 m_ready
);

    integer i, j;

    always @* begin
        s_ready = {BRANCHES{m_ready}};
        for (i = 0; i < BRANCHES; i = i + 1)
            for (j = 0; j < BRANCHES; j = j + 1)
                if (i != j)
                    s_ready[i] = s_ready[i] && s_valid[j];
    end

    assign m_valid = &s_valid;

endmodule

`default_nettype wire
