`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module EmuRam #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PAGE_COUNT      = 'h10000,
    parameter   MAX_INFLIGHT    = 8,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input  wire                 clk,
    input  wire                 rst,

    `AXI4_SLAVE_IF              (s_axi,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)

);

    // TODO: calculate size required by LSU using FIFO parameters
    parameter LSU_PF_COUNT = 16;

    initial begin
        if (ADDR_WIDTH < 1 || ADDR_WIDTH > 64) begin
            $display("%m: ADDR_WIDTH is required to be in [1,64]");
            $finish;
        end
        if (DATA_WIDTH != 8 && DATA_WIDTH != 16 && DATA_WIDTH != 32 && DATA_WIDTH != 64) begin
            $display("%m: DATA_WIDTH is required to be 8, 16, 32 or 64");
            $finish;
        end
        if (ID_WIDTH < 1 || ID_WIDTH > 16) begin
            $display("%m: ID_WIDTH is required to be in [1,16]");
            $finish;
        end
        if (PAGE_COUNT <= 0) begin
            $display("%m: PAGE_COUNT is required to be > 0");
            $finish;
        end
    end

    wire                     areq_valid;
    wire                     areq_write;
    wire [ID_WIDTH-1:0]      areq_id;
    wire [ADDR_WIDTH-1:0]    areq_addr;
    wire [7:0]               areq_len;
    wire [2:0]               areq_size;
    wire [1:0]               areq_burst;

    wire                     wreq_valid;
    wire [DATA_WIDTH-1:0]    wreq_data;
    wire [DATA_WIDTH/8-1:0]  wreq_strb;
    wire                     wreq_last;

    wire                     breq_valid;
    wire [ID_WIDTH-1:0]      breq_id;

    wire                     rreq_valid;
    wire [ID_WIDTH-1:0]      rreq_id;

    wire [DATA_WIDTH-1:0]    rresp_data;
    wire                     rresp_last;

    emulib_rammodel_frontend #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .MAX_INFLIGHT   (MAX_INFLIGHT),
        .R_DELAY        (R_DELAY),
        .W_DELAY        (W_DELAY)
    )
    frontend (

        .clk                    (clk),
        .rst                    (rst),

        `AXI4_CONNECT           (target_axi, s_axi),

        .areq_valid             (areq_valid),
        .areq_write             (areq_write),
        .areq_id                (areq_id),
        .areq_addr              (areq_addr),
        .areq_len               (areq_len),
        .areq_size              (areq_size),
        .areq_burst             (areq_burst),

        .wreq_valid             (wreq_valid),
        .wreq_data              (wreq_data),
        .wreq_strb              (wreq_strb),
        .wreq_last              (wreq_last),

        .breq_valid             (breq_valid),
        .breq_id                (breq_id),

        .rreq_valid             (rreq_valid),
        .rreq_id                (rreq_id),

        .rresp_data             (rresp_data),
        .rresp_last             (rresp_last)

    );

    emulib_rammodel_backend #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .PAGE_COUNT     (PAGE_COUNT),
        .MAX_INFLIGHT   (MAX_INFLIGHT)
    )
    backend (

        .clk                    (clk),
        .rst                    (rst),

        .areq_valid             (areq_valid),
        .areq_write             (areq_write),
        .areq_id                (areq_id),
        .areq_addr              (areq_addr),
        .areq_len               (areq_len),
        .areq_size              (areq_size),
        .areq_burst             (areq_burst),

        .wreq_valid             (wreq_valid),
        .wreq_data              (wreq_data),
        .wreq_strb              (wreq_strb),
        .wreq_last              (wreq_last),

        .breq_valid             (breq_valid),
        .breq_id                (breq_id),

        .rreq_valid             (rreq_valid),
        .rreq_id                (rreq_id),

        .rresp_data             (rresp_data),
        .rresp_last             (rresp_last)

    );

endmodule
