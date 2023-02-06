`timescale 1ns / 1ps

module EmuAXIRemapCtrl #(
    parameter   CTRL_ADDR_WIDTH = 32,
    parameter   ADDR_WIDTH  = 32
)(
    input  wire                     clk,
    input  wire                     rst,

    input  wire                         ctrl_wen,
    input  wire [CTRL_ADDR_WIDTH-1:0]   ctrl_waddr,
    input  wire [31:0]                  ctrl_wdata,
    input  wire                         ctrl_ren,
    input  wire [CTRL_ADDR_WIDTH-1:0]   ctrl_raddr,
    output reg  [31:0]                  ctrl_rdata,

    input  wire [ADDR_WIDTH-1:0]    araddr_i,
    output wire [ADDR_WIDTH-1:0]    araddr_o,
    input  wire [ADDR_WIDTH-1:0]    awaddr_i,
    output wire [ADDR_WIDTH-1:0]    awaddr_o
);

    // Registers
    // 0x00 -> BASE_LO
    // 0x04 -> BASE_HI
    // 0x08 -> MASK_LO
    // 0x0c -> MASK_HI

    reg [51:0] base, mask; // high 52 bits

    always @(posedge clk) begin
        if (rst) begin
            base <= 52'h00000000_00000;
            mask <= 52'hffffffff_fffff;
        end
        else if (ctrl_wen) begin
            case (ctrl_waddr[3:2])
                2'd0:   base[19: 0] <= ctrl_wdata[31:12];
                2'd1:   base[51:20] <= ctrl_wdata;
                2'd2:   mask[19: 0] <= ctrl_wdata[31:12];
                2'd3:   mask[51:20] <= ctrl_wdata;
            endcase
        end
    end

    wire [63:0] full_base = {base, 12'h000};
    wire [63:0] full_mask = {mask, 12'hfff};

    always @* begin
        case (ctrl_raddr[3:2])
            2'd0:   ctrl_rdata = full_base[31: 0];
            2'd1:   ctrl_rdata = full_base[63:32];
            2'd2:   ctrl_rdata = full_mask[31: 0];
            2'd3:   ctrl_rdata = full_mask[63:32];
        endcase
    end

    wire [ADDR_WIDTH-1:0] real_base = full_base[ADDR_WIDTH-1:0];
    wire [ADDR_WIDTH-1:0] real_mask = full_mask[ADDR_WIDTH-1:0];

    assign araddr_o = (real_mask & araddr_i) | (~real_mask & real_base);
    assign awaddr_o = (real_mask & awaddr_i) | (~real_mask & real_base);

endmodule
