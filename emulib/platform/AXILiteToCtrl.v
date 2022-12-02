`timescale 1ns / 1ps

`include "axi.vh"

module AXILiteToCtrl (

    input  wire         clk,
    input  wire         rst,

    output wire         ctrl_wen,
    output reg  [ 9:0]  ctrl_waddr,
    output reg  [31:0]  ctrl_wdata,
    output wire         ctrl_ren,
    output reg  [ 9:0]  ctrl_raddr,
    input  wire [31:0]  ctrl_rdata,

    `AXI4LITE_SLAVE_IF  (s_axilite, 12, 32)
);

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
            ctrl_raddr <= s_axilite_araddr[11:2];

    reg [31:0] read_data;

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
            ctrl_waddr <= s_axilite_awaddr[11:2];

    wire [31:0] extended_wstrb = {
        {8{s_axilite_wstrb[3]}},
        {8{s_axilite_wstrb[2]}},
        {8{s_axilite_wstrb[1]}},
        {8{s_axilite_wstrb[0]}}
    };

    always @(posedge clk)
        if (s_axilite_wvalid && s_axilite_wready)
            ctrl_wdata <= s_axilite_wdata & extended_wstrb;

    assign ctrl_wen = w_state == W_STATE_WRITE;

    assign s_axilite_awready    = w_state == W_STATE_AXI_AW;
    assign s_axilite_wready     = w_state == W_STATE_AXI_W;
    assign s_axilite_bvalid     = w_state == W_STATE_AXI_B;
    assign s_axilite_bresp      = 2'd0;

endmodule
