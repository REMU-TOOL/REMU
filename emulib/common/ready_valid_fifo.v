`timescale 1ns / 1ps
`default_nettype none

module emulib_ready_valid_fifo #(
    parameter WIDTH     = 32,
    parameter DEPTH     = 8,

    parameter CNTW      = $clog2(DEPTH+1)
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 ivalid,
    output wire                 iready,
    input  wire [WIDTH-1:0]     idata,

    output reg                  ovalid,
    input  wire                 oready,
    output wire [WIDTH-1:0]     odata,

    output reg  [CNTW-1:0]      count

);

    wire full, empty;
    wire rinc = oready || !ovalid;

    emulib_fifo #(
        .WIDTH  (WIDTH),
        .DEPTH  (DEPTH-1) // the rdata register provides 1 extra depth
    ) fifo (
        .clk        (clk),
        .rst        (rst),
        .winc       (ivalid),
        .wfull      (full),
        .wdata      (idata),
        .rinc       (rinc),
        .rempty     (empty),
        .rdata      (odata)
    );

    always @(posedge clk) begin
        if (rst)
            ovalid <= 1'b0;
        else if (rinc)
            ovalid <= !empty;
    end

    always @(posedge clk) begin
        if (rst)
            count <= 0;
        else
            count <= count + (ivalid && iready) - (ovalid && oready);
    end

    assign iready = !full;

`ifdef FORMAL

    reg f_past_valid;
    initial f_past_valid = 1'b0;

    always @(posedge clk)
        f_past_valid <= 1'b1;

    always @*
        if (!f_past_valid)
            assume(rst);

    integer f_depth;

    always @(posedge clk) begin
        if (rst)
            f_depth <= 0;
        else
            f_depth <= f_depth + (ivalid && iready) - (ovalid && oready);
    end

    always @(posedge clk) begin
        if (!rst) begin
            assert(f_depth <= DEPTH);
            assert(f_depth >= 0);
            assert(f_depth == count);
            assert(!full || !empty);
        end
    end

`endif

endmodule

`default_nettype wire
