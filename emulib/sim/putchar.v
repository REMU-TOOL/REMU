`timescale 1ns / 1ps
`default_nettype none

module EmuPutChar (
    input  wire         clk,
    input  wire         rst,
    input  wire         valid,
    input  wire [7:0]   data
);

    always @(posedge clk) begin
        if (!rst && valid) begin
            $write("%c", data);
            $fflush();
        end
    end

endmodule

`default_nettype wire
