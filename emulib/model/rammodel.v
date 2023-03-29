`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

(* __emu_model_type = "rammodel" *)
module EmuRam #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MEM_SIZE        = 64'h10000000,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8,
    parameter   TIMING_TYPE     = "fixed"
)(
    input  wire                 clk,
    input  wire                 rst,

    `AXI4_SLAVE_IF              (s_axi,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)
);

    initial begin
        if (ADDR_WIDTH <= 0) begin
            $display("%m: ADDR_WIDTH must be greater than 0");
            $finish;
        end
        if (ADDR_WIDTH > 64) begin
            $display("%m: ADDR_WIDTH must not be greater than 64");
            $finish;
        end
        if (DATA_WIDTH != 8 &&
            DATA_WIDTH != 16 &&
            DATA_WIDTH != 32 &&
            DATA_WIDTH != 64 &&
            DATA_WIDTH != 128 &&
            DATA_WIDTH != 256 &&
            DATA_WIDTH != 512 &&
            DATA_WIDTH != 1024) begin
            $display("%m: DATA_WIDTH must be 8, 16, 32, 64, 128, 256, 512 or 1024");
            $finish;
        end
        if (ID_WIDTH <= 0) begin
            $display("%m: ID_WIDTH must be greater than 0");
            $finish;
        end
        if (ID_WIDTH > 8) begin
            $display("%m: ID_WIDTH must not be greater than 8");
            $finish;
        end
        if (MEM_SIZE % 'h1000 != 0) begin
            $display("%m: MEM_SIZE must be aligned to 4KB");
            $finish;
        end
    end

    wire                     arreq_valid;
    wire [ID_WIDTH-1:0]      arreq_id;
    wire [ADDR_WIDTH-1:0]    arreq_addr;
    wire [7:0]               arreq_len;
    wire [2:0]               arreq_size;
    wire [1:0]               arreq_burst;

    wire                     awreq_valid;
    wire [ID_WIDTH-1:0]      awreq_id;
    wire [ADDR_WIDTH-1:0]    awreq_addr;
    wire [7:0]               awreq_len;
    wire [2:0]               awreq_size;
    wire [1:0]               awreq_burst;

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
        .MAX_R_INFLIGHT (MAX_R_INFLIGHT),
        .MAX_W_INFLIGHT (MAX_W_INFLIGHT),
        .TIMING_TYPE    (TIMING_TYPE)
    )
    frontend (

        .clk                    (clk),
        .rst                    (rst),

        `AXI4_CONNECT           (target_axi, s_axi),

        .arreq_valid            (arreq_valid),
        .arreq_id               (arreq_id),
        .arreq_addr             (arreq_addr),
        .arreq_len              (arreq_len),
        .arreq_size             (arreq_size),
        .arreq_burst            (arreq_burst),

        .awreq_valid            (awreq_valid),
        .awreq_id               (awreq_id),
        .awreq_addr             (awreq_addr),
        .awreq_len              (awreq_len),
        .awreq_size             (awreq_size),
        .awreq_burst            (awreq_burst),

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
        .MEM_SIZE       (MEM_SIZE),
        .MAX_R_INFLIGHT (MAX_R_INFLIGHT),
        .MAX_W_INFLIGHT (MAX_W_INFLIGHT)
    )
    backend (

        .clk                    (clk),
        .rst                    (rst),

        .arreq_valid            (arreq_valid),
        .arreq_id               (arreq_id),
        .arreq_addr             (arreq_addr),
        .arreq_len              (arreq_len),
        .arreq_size             (arreq_size),
        .arreq_burst            (arreq_burst),

        .awreq_valid            (awreq_valid),
        .awreq_id               (awreq_id),
        .awreq_addr             (awreq_addr),
        .awreq_len              (awreq_len),
        .awreq_size             (awreq_size),
        .awreq_burst            (awreq_burst),

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
