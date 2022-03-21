`timescale 1ns / 1ps
`default_nettype none

module emulib_register_slice #(
    parameter   DATA_WIDTH      = 1
)(
    input  wire                     clk,
    input  wire                     resetn,

    input  wire                     s_valid,
    input  wire [DATA_WIDTH-1:0]    s_data,
    output reg                      s_ready,

    output reg                      m_valid,
    output reg  [DATA_WIDTH-1:0]    m_data,
    input  wire                     m_ready
);

    reg [DATA_WIDTH-1:0] s_data_r;

    always @(posedge clk) begin
        if (!resetn)
            m_valid <= 1'b0;
        else if (!s_ready || s_valid)
            m_valid <= 1'b1;
        else if (m_ready)
            m_valid <= 1'b0;
    end

    always @(posedge clk) begin
        if (!resetn)
            s_ready <= 1'b1;
        else if (!m_valid || m_ready)
            s_ready <= 1'b1;
        else if (s_valid)
            s_ready <= 1'b0;
    end

    always @(posedge clk) if (!m_valid || m_ready) m_data <= s_ready ? s_data : s_data_r;
    always @(posedge clk) if (s_ready) s_data_r <= s_data;

`ifdef FORMAL

    reg f_past_valid;
    initial f_past_valid = 1'b0;

    always @(posedge clk)
        f_past_valid <= 1'b1;

    always @*
        if (!f_past_valid)
            assume(!resetn);

    // Check for functionality

    localparam F_Q_DEPTH_LOG2 = 2;
    reg [DATA_WIDTH-1:0] f_data_q [(1<<F_Q_DEPTH_LOG2)-1:0];
    reg [F_Q_DEPTH_LOG2-1:0] f_wp, f_rp;

    always @(posedge clk) begin
        if (!resetn) begin
            f_wp <= 0;
            f_rp <= 0;
        end
        else begin
            if (s_valid && s_ready) begin
                f_wp <= f_wp + 1;
                f_data_q[f_wp] <= s_data;
            end
            if (m_valid && m_ready) begin
                f_rp <= f_rp + 1;
                assert(f_data_q[f_rp] == m_data);
            end
        end
    end

    // Check for stability

    always @(posedge clk) begin
        if (f_past_valid && $past(resetn)) begin
            if ($past(m_valid && !m_ready)) begin
                assert(m_valid);
                assert($stable(m_data));
            end
        end
    end

`endif

endmodule

`default_nettype wire
