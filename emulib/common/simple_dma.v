`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_custom.vh"

module emulib_simple_dma #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 32,
    parameter   COUNT_WIDTH     = 10
)(

    input  wire                     clk,
    input  wire                     rst,

    input  wire                     s_read_addr_valid,
    output wire                     s_read_addr_ready,
    input  wire [ADDR_WIDTH-1:0]    s_read_addr,

    input  wire                     s_read_count_valid,
    output wire                     s_read_count_ready,
    input  wire [COUNT_WIDTH-1:0]   s_read_count,

    output wire                     m_read_data_valid,
    input  wire                     m_read_data_ready,
    output wire [DATA_WIDTH-1:0]    m_read_data,

    input  wire                     s_write_addr_valid,
    output wire                     s_write_addr_ready,
    input  wire [ADDR_WIDTH-1:0]    s_write_addr,

    input  wire                     s_write_count_valid,
    output wire                     s_write_count_ready,
    input  wire [COUNT_WIDTH-1:0]   s_write_count,

    input  wire                     s_write_data_valid,
    output wire                     s_write_data_ready,
    input  wire [DATA_WIDTH-1:0]    s_write_data,

    `AXI4_MASTER_IF_NO_ID           (m_axi, 32, 32),

    output wire                     r_idle,
    output wire                     w_idle

);

    reg [ADDR_WIDTH-1:0] read_addr, write_addr;
    reg [COUNT_WIDTH-1:0] read_count, write_count;

    localparam [1:0]
        R_IDLE  = 2'd0,
        R_DO_AR = 2'd1,
        R_DO_R  = 2'd2;

    reg [1:0] r_state, r_state_next;

    localparam [1:0]
        W_IDLE  = 2'd0,
        W_DO_AW = 2'd1,
        W_DO_W  = 2'd2,
        W_DO_B  = 2'd3;

    reg [1:0] w_state, w_state_next;

    wire m_axi_arfire       = m_axi_arvalid && m_axi_arready;
    wire m_axi_rfire        = m_axi_rvalid && m_axi_rready;
    wire m_axi_awfire       = m_axi_awvalid && m_axi_awready;
    wire m_axi_wfire        = m_axi_wvalid && m_axi_wready;
    wire m_axi_bfire        = m_axi_bvalid && m_axi_bready;

    wire s_read_addr_fire   = s_read_addr_valid && s_read_addr_ready;
    wire s_read_count_fire  = s_read_count_valid && s_read_count_ready;
    wire s_write_addr_fire  = s_write_addr_valid && s_write_addr_ready;
    wire s_write_count_fire = s_write_count_valid && s_write_count_ready;

    wire read_start         = read_count != 0;
    wire write_start        = write_count != 0;

    reg [7:0] wlen;

    ////////////////////////////// READ //////////////////////////////

    always @(posedge clk)
        if (rst)
            r_state <= R_IDLE;
        else
            r_state <= r_state_next;

    always @*
        case (r_state)
            R_IDLE:     r_state_next = s_read_count_fire && s_read_count != 0 ? R_DO_AR : R_IDLE;
            R_DO_AR:    r_state_next = m_axi_arfire ? R_DO_R : R_DO_AR;
            R_DO_R:     r_state_next = m_axi_rfire && m_axi_rlast ?
                                       (read_start ? R_DO_AR : R_IDLE) :
                                       R_DO_R;
            default:    r_state_next = R_IDLE;
        endcase

    assign m_axi_arvalid        = r_state == R_DO_AR;
    assign m_axi_araddr         = read_addr;
    assign m_axi_arlen          = read_count > 'hff ? 'hff : read_count - 1;
    assign m_axi_arsize         = $clog2(DATA_WIDTH / 8);
    assign m_axi_arburst        = 2'b01;    // INCR
    assign m_axi_arprot         = 3'b010;
    assign m_axi_arlock         = 1'b0;
    assign m_axi_arcache        = 4'd0;
    assign m_axi_arqos          = 4'd0;
    assign m_axi_arregion       = 4'd0;

    assign m_axi_rready         = r_state == R_DO_R && m_read_data_ready;
    assign m_read_data_valid    = r_state == R_DO_R && m_axi_rvalid;
    assign m_read_data          = m_axi_rdata;

    assign s_read_addr_ready    = r_state == R_IDLE;
    assign s_read_count_ready   = r_state == R_IDLE;
    assign r_idle               = r_state == R_IDLE;

    always @(posedge clk)
        if (rst)
            read_addr <= 0;
        else if (m_axi_arfire)
            read_addr <= read_addr + ((m_axi_arlen + 1) << m_axi_arsize);
        else if (s_read_addr_fire)
            read_addr <= s_read_addr;

    always @(posedge clk)
        if (rst)
            read_count <= 0;
        else if (m_axi_arfire)
            read_count <= read_count - (m_axi_arlen + 1);
        else if (s_read_count_fire)
            read_count <= s_read_count;

    ////////////////////////////// WRITE //////////////////////////////

    always @(posedge clk)
        if (rst)
            w_state <= W_IDLE;
        else
            w_state <= w_state_next;

    always @*
        case (w_state)
            W_IDLE:     w_state_next = s_write_count_fire && s_write_count != 0 ? W_DO_AW : W_IDLE;
            W_DO_AW:    w_state_next = m_axi_awfire ? W_DO_W : W_DO_AW;
            W_DO_W:     w_state_next = m_axi_wfire && m_axi_wlast ? W_DO_B : W_DO_W;
            W_DO_B:     w_state_next = m_axi_bfire ?
                                       (write_start ? W_DO_AW : W_IDLE) :
                                       W_DO_B;
            default:    w_state_next = W_IDLE;
        endcase

    always @(posedge clk)
        if (rst)
            wlen <= 8'd0;
        else if (m_axi_awfire)
            wlen <= m_axi_awlen;
        else if (m_axi_wfire)
            wlen <= wlen - 8'd1;

    assign m_axi_awvalid        = w_state == W_DO_AW;
    assign m_axi_awaddr         = write_addr;
    assign m_axi_awlen          = write_count > 'hff ? 'hff : write_count - 1;
    assign m_axi_awsize         = $clog2(DATA_WIDTH / 8);
    assign m_axi_awburst        = 2'b01;    // INCR
    assign m_axi_awprot         = 3'b010;
    assign m_axi_awlock         = 1'b0;
    assign m_axi_awcache        = 4'd0;
    assign m_axi_awqos          = 4'd0;
    assign m_axi_awregion       = 4'd0;

    assign m_axi_wvalid         = w_state == W_DO_W && s_write_data_valid;
    assign s_write_data_ready   = w_state == W_DO_W && m_axi_wready;
    assign m_axi_wdata          = s_write_data;
    assign m_axi_wstrb          = {(DATA_WIDTH / 8){1'b1}};
    assign m_axi_wlast          = wlen == 8'd0;

    assign m_axi_bready         = w_state == W_DO_B;

    assign s_write_addr_ready   = w_state == W_IDLE;
    assign s_write_count_ready  = w_state == W_IDLE;
    assign w_idle               = w_state == W_IDLE;

    always @(posedge clk)
        if (rst)
            write_addr <= 0;
        else if (m_axi_awfire)
            write_addr <= write_addr + ((m_axi_awlen + 1) << m_axi_awsize);
        else if (s_write_addr_fire)
            write_addr <= s_write_addr;

    always @(posedge clk)
        if (rst)
            write_count <= 0;
        else if (m_axi_awfire)
            write_count <= write_count - (m_axi_awlen + 1);
        else if (s_write_count_fire)
            write_count <= s_write_count;

endmodule

`default_nettype wire
