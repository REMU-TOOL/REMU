`timescale 1ns / 1ps

module emulib_ready_valid_fifo #(
    parameter WIDTH     = 32,
    parameter DEPTH     = 8,
    parameter FAST_READ = 0
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 ivalid,
    output wire                 iready,
    input  wire [WIDTH-1:0]     idata,

    output reg                  ovalid = 1'b0,
    input  wire                 oready,
    output wire [WIDTH-1:0]     odata

);

    wire full, empty;
    wire rinc;

    if (FAST_READ) begin
        assign rinc = oready;
        always @*
            ovalid = !empty;
    end
    else begin
        assign rinc = oready || !ovalid;
        always @(posedge clk) begin
            if (rst)
                ovalid <= 1'b0;
            else if (rinc)
                ovalid <= !empty;
        end
    end

    assign iready = !full;

    emulib_fifo #(
        .WIDTH      (WIDTH),
        .DEPTH      (DEPTH),
        .FAST_READ  (FAST_READ)
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
            assert(!full || !empty);
        end
    end

`endif

endmodule
