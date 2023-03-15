`timescale 1ns / 1ps

module EmuAXIRemapCtrl #(
    parameter   CTRL_ADDR_WIDTH = 32,
    parameter   AXI_ADDR_WIDTH  = 32
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                         ctrl_wen,
    input  wire [CTRL_ADDR_WIDTH-1:0]   ctrl_waddr,
    input  wire [31:0]                  ctrl_wdata,
    input  wire                         ctrl_ren,
    input  wire [CTRL_ADDR_WIDTH-1:0]   ctrl_raddr,
    output reg  [31:0]                  ctrl_rdata,

    input  wire [AXI_ADDR_WIDTH-1:0]    araddr_i,
    output wire [39:0]                  araddr_o,
    input  wire [AXI_ADDR_WIDTH-1:0]    awaddr_i,
    output wire [39:0]                  awaddr_o
);

    // Registers
    // 0x00 -> BASE_12
    // 0x04 -> MASK_12

    reg [27:0] base, mask; // high 28 bits

    always @(posedge clk) begin
        if (rst) begin
            base <= 28'h0000000;
            mask <= 28'hfffffff;
        end
        else if (ctrl_wen) begin
            case (ctrl_waddr[2:2])
                1'd0:   base <= ctrl_wdata[27:0];
                1'd1:   mask <= ctrl_wdata[27:0];
            endcase
        end
    end

    always @* begin
        case (ctrl_raddr[2:2])
            1'd0:   ctrl_rdata = {4'd0, base};
            1'd1:   ctrl_rdata = {4'd0, mask};
        endcase
    end

    wire [39:0] full_base = {base, 12'h000};
    wire [39:0] full_mask = {mask, 12'hfff};
    wire [39:0] araddr_i_ext = {{40-AXI_ADDR_WIDTH{1'b0}}, araddr_i};
    wire [39:0] awaddr_i_ext = {{40-AXI_ADDR_WIDTH{1'b0}}, awaddr_i};

    assign araddr_o = (full_mask & araddr_i_ext) | (~full_mask & full_base);
    assign awaddr_o = (full_mask & awaddr_i_ext) | (~full_mask & full_base);

endmodule
