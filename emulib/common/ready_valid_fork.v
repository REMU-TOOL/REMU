`timescale 1ns / 1ps
`default_nettype none

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
        m_valid = {BRANCHES{s_valid}};
        for (i = 0; i < BRANCHES; i = i + 1)
            for (j = 0; j < BRANCHES; j = j + 1)
                if (i != j)
                    m_valid[i] = m_valid[i] && m_ready[j];
    end

    assign s_ready = &m_ready;

endmodule

`default_nettype wire
