`timescale 1ns / 1ps

module ctrlbus_bridge #(
    parameter   ADDR_WIDTH  = 32,
    parameter   DATA_WIDTH  = 32,
    parameter   M_COUNT     = 1,
    parameter   M_BASE_LIST = {32'h00000000},
    parameter   M_MASK_LIST = {32'h00000000}
)(
    input  wire                             s_ctrl_wen,
    input  wire [ADDR_WIDTH-1:0]            s_ctrl_waddr,
    input  wire [DATA_WIDTH-1:0]            s_ctrl_wdata,
    input  wire                             s_ctrl_ren,
    input  wire [ADDR_WIDTH-1:0]            s_ctrl_raddr,
    output reg  [DATA_WIDTH-1:0]            s_ctrl_rdata,

    output wire [M_COUNT-1:0]               m_ctrl_wen,
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_ctrl_waddr,
    output wire [M_COUNT*DATA_WIDTH-1:0]    m_ctrl_wdata,
    output wire [M_COUNT-1:0]               m_ctrl_ren,
    output wire [M_COUNT*ADDR_WIDTH-1:0]    m_ctrl_raddr,
    input  wire [M_COUNT*DATA_WIDTH-1:0]    m_ctrl_rdata
);

    function [ADDR_WIDTH-1:0] get_base(input integer i);
    begin
        get_base = M_BASE_LIST[i*ADDR_WIDTH+:ADDR_WIDTH];
    end
    endfunction

    function [ADDR_WIDTH-1:0] get_mask(input integer i);
    begin
        get_mask = M_MASK_LIST[i*ADDR_WIDTH+:ADDR_WIDTH];
    end
    endfunction

    wire [M_COUNT-1:0] w_sel, r_sel;

    genvar i;

    for (i=0; i<M_COUNT; i=i+1) begin
        assign w_sel[i] = (s_ctrl_waddr & get_mask(i) == get_base(i) & get_mask(i));
        assign m_ctrl_wen[i] = s_ctrl_wen && w_sel[i];
        assign m_ctrl_waddr[i*ADDR_WIDTH+:ADDR_WIDTH] = s_ctrl_waddr;
        assign m_ctrl_wdata[i*DATA_WIDTH+:DATA_WIDTH] = s_ctrl_wdata;

        assign r_sel[i] = (s_ctrl_raddr & get_mask(i) == get_base(i) & get_mask(i));
        assign m_ctrl_ren[i] = s_ctrl_ren && r_sel[i];
        assign m_ctrl_raddr[i*ADDR_WIDTH+:ADDR_WIDTH] = s_ctrl_raddr;
    end

    integer index;

    always @* begin
        for (index=0; index<M_COUNT; index=index+1)
            s_ctrl_rdata = s_ctrl_rdata | {DATA_WIDTH{r_sel[index]}} & m_ctrl_rdata[index*DATA_WIDTH+:DATA_WIDTH];
    end

endmodule
