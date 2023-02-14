`timescale 1ns / 1ps

`include "axi.vh"

module AXILiteToCtrl #(
    parameter   ADDR_WIDTH  = 12,
    parameter   DATA_WIDTH  = 32
)(

    input  wire                     clk,
    input  wire                     rst,

    output wire                     ctrl_wen,
    output reg  [ADDR_WIDTH-1:0]    ctrl_waddr,
    output reg  [DATA_WIDTH-1:0]    ctrl_wdata,
    output wire                     ctrl_ren,
    output reg  [ADDR_WIDTH-1:0]    ctrl_raddr,
    input  wire [DATA_WIDTH-1:0]    ctrl_rdata,

    `AXI4LITE_SLAVE_IF  (s_axilite, ADDR_WIDTH, DATA_WIDTH)
);

    genvar i;

    localparam [1:0]
        R_STATE_AXI_AR  = 2'd0,
        R_STATE_READ    = 2'd1,
        R_STATE_AXI_R   = 2'd2;

    reg [1:0] r_state, r_state_next;

    always @(posedge clk) begin
        if (rst)
            r_state <= R_STATE_AXI_AR;
        else
            r_state <= r_state_next;
    end

    always @* begin
        case (r_state)
            R_STATE_AXI_AR: r_state_next = s_axilite_arvalid ? R_STATE_READ : R_STATE_AXI_AR;
            R_STATE_READ:   r_state_next = R_STATE_AXI_R;
            R_STATE_AXI_R:  r_state_next = s_axilite_rready ? R_STATE_AXI_AR : R_STATE_AXI_R;
            default:        r_state_next = R_STATE_AXI_AR;
        endcase
    end

    always @(posedge clk)
        if (s_axilite_arvalid && s_axilite_arready)
            ctrl_raddr <= s_axilite_araddr;

    reg [DATA_WIDTH-1:0] read_data;

    always @(posedge clk)
        if (r_state == R_STATE_READ)
            read_data <= ctrl_rdata;

    assign ctrl_ren = r_state == R_STATE_READ;

    assign s_axilite_arready    = r_state == R_STATE_AXI_AR;
    assign s_axilite_rvalid     = r_state == R_STATE_AXI_R;
    assign s_axilite_rdata      = read_data;
    assign s_axilite_rresp      = 2'd0;

    localparam [1:0]
        W_STATE_AXI_AW  = 2'd0,
        W_STATE_AXI_W   = 2'd1,
        W_STATE_WRITE   = 2'd2,
        W_STATE_AXI_B   = 2'd3;

    reg [1:0] w_state, w_state_next;

    always @(posedge clk) begin
        if (rst)
            w_state <= W_STATE_AXI_AW;
        else
            w_state <= w_state_next;
    end

    always @* begin
        case (w_state)
            W_STATE_AXI_AW: w_state_next = s_axilite_awvalid ? W_STATE_AXI_W : W_STATE_AXI_AW;
            W_STATE_AXI_W:  w_state_next = s_axilite_wvalid ? W_STATE_WRITE : W_STATE_AXI_W;
            W_STATE_WRITE:  w_state_next = W_STATE_AXI_B;
            W_STATE_AXI_B:  w_state_next = s_axilite_bready ? W_STATE_AXI_AW : W_STATE_AXI_B;
            default:        w_state_next = W_STATE_AXI_AW;
        endcase
    end

    always @(posedge clk)
        if (s_axilite_awvalid && s_axilite_awready)
            ctrl_waddr <= s_axilite_awaddr;

    wire [DATA_WIDTH-1:0] extended_wstrb;

    for (i=0; i<DATA_WIDTH/8; i=i+1) begin
        assign extended_wstrb[i*8+:8] = {8{s_axilite_wstrb[i]}};
    end

    always @(posedge clk)
        if (s_axilite_wvalid && s_axilite_wready)
            ctrl_wdata <= s_axilite_wdata & extended_wstrb;

    assign ctrl_wen = w_state == W_STATE_WRITE;

    assign s_axilite_awready    = w_state == W_STATE_AXI_AW;
    assign s_axilite_wready     = w_state == W_STATE_AXI_W;
    assign s_axilite_bvalid     = w_state == W_STATE_AXI_B;
    assign s_axilite_bresp      = 2'd0;

endmodule
