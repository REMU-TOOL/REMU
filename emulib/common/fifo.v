`timescale 1ns / 1ps

module emulib_fifo #(
    parameter WIDTH     = 32,
    parameter DEPTH     = 8,

    parameter CNTW      = DEPTH > 1 ? $clog2(DEPTH) : 1
)(

    input  wire                 clk,
    input  wire                 rst,

    input  wire                 winc,
    output reg                  wfull,
    input  wire [WIDTH-1:0]     wdata,

    input  wire                 rinc,
    output reg                  rempty,
    output reg  [WIDTH-1:0]     rdata

);

    initial begin
        if (WIDTH <= 0) begin
            $display("%m: WIDTH must be a positive number");
            $finish;
        end
        if (DEPTH <= 0) begin
            $display("%m: DEPTH must be a positive number");
            $finish;
        end
    end

    localparam [CNTW-1:0]
        PTR_MAX = DEPTH - 1,
        PTR_ZRO = 0,
        PTR_INC = 1;

    reg [WIDTH-1:0] data [DEPTH-1:0];
    reg [CNTW-1:0] rp, wp;

    wire wfire = winc && !wfull;
    wire rfire = rinc && !rempty;

    wire [CNTW-1:0] rp_inc = rp == PTR_MAX ? PTR_ZRO : rp + PTR_INC;
    wire [CNTW-1:0] wp_inc = wp == PTR_MAX ? PTR_ZRO : wp + PTR_INC;

    always @(posedge clk)
        if (rst)
            wp <= PTR_ZRO;
        else if (wfire)
            wp <= wp_inc;

    always @(posedge clk)
        if (rst)
            rp <= PTR_ZRO;
        else if (rfire)
            rp <= rp_inc;

    always @(posedge clk)
        if (rst)
            wfull <= 1'b0;
        else if (rfire)
            wfull <= 1'b0;
        else if (wfire && wp_inc == rp)
            wfull <= 1'b1;

    always @(posedge clk)
        if (rst)
            rempty <= 1'b1;
        else if (wfire)
            rempty <= 1'b0;
        else if (rfire && rp_inc == wp)
            rempty <= 1'b1;

    always @(posedge clk)
        if (wfire) data[wp] <= wdata;

    always @(posedge clk)
        if (rfire) rdata <= data[rp];

`ifdef SIM_LOG_FIFO

    always @(posedge clk) begin
        if (!rst) begin
            case ({wen && !wfull, ren && !rempty})
                2'b01: begin
                    $display("[%0d ns] %m: OUT: %h, %0d/%0d", $time, wdata, count - 1, DEPTH);
                end
                2'b10: begin
                    $display("[%0d ns] %m: IN: %h, %0d/%0d", $time, rdata, count + 1, DEPTH);
                end
                2'b11: begin
                    $display("[%0d ns] %m: IN: %h, OUT: %h, %0d/%0d", $time, wdata, data[rp], count, DEPTH);
                end
            endcase
        end
    end

`endif

endmodule
