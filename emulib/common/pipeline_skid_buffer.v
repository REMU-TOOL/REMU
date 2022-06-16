`timescale 1ns / 1ps
`default_nettype none

module emulib_pipeline_skid_buffer #(
    parameter   DATA_WIDTH      = 1
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                     i_valid,
    input  wire [DATA_WIDTH-1:0]    i_data,
    output reg                      i_ready,

    output reg                      o_valid,
    output reg  [DATA_WIDTH-1:0]    o_data,
    input  wire                     o_ready
);

    reg [DATA_WIDTH-1:0] i_data_r;

    always @(posedge clk) begin
        if (rst)
            o_valid <= 1'b0;
        else if (!i_ready || i_valid)
            o_valid <= 1'b1;
        else if (o_ready)
            o_valid <= 1'b0;
    end

    always @(posedge clk) begin
        if (rst)
            i_ready <= 1'b1;
        else if (!o_valid || o_ready)
            i_ready <= 1'b1;
        else if (i_valid)
            i_ready <= 1'b0;
    end

    always @(posedge clk) if (!o_valid || o_ready) o_data <= i_ready ? i_data : i_data_r;
    always @(posedge clk) if (i_ready) i_data_r <= i_data;

`ifdef FORMAL

    reg f_past_valid;
    initial f_past_valid = 1'b0;

    always @(posedge clk)
        f_past_valid <= 1'b1;

    always @*
        if (!f_past_valid)
            assume(rst);

    // Check for functionality

    localparam F_Q_DEPTH_LOG2 = 2;
    reg [DATA_WIDTH-1:0] f_data_q [(1<<F_Q_DEPTH_LOG2)-1:0];
    reg [F_Q_DEPTH_LOG2-1:0] f_wp, f_rp;

    always @(posedge clk) begin
        if (rst) begin
            f_wp <= 0;
            f_rp <= 0;
        end
        else begin
            if (i_valid && i_ready) begin
                f_wp <= f_wp + 1;
                f_data_q[f_wp] <= i_data;
            end
            if (o_valid && o_ready) begin
                f_rp <= f_rp + 1;
                assert(f_data_q[f_rp] == o_data);
            end
        end
    end

    // Check for stability

    always @(posedge clk) begin
        if (f_past_valid && $past(resetn)) begin
            if ($past(o_valid && !o_ready)) begin
                assert(o_valid);
                assert($stable(o_data));
            end
        end
    end

`endif

endmodule

`default_nettype wire
