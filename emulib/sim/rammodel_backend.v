`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_backend #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MEM_SIZE        = 64'h10000000,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8
)(

    input  wire                     clk,
    input  wire                     rst,

    input  wire                     arreq_valid,
    input  wire [ID_WIDTH-1:0]      arreq_id,
    input  wire [ADDR_WIDTH-1:0]    arreq_addr,
    input  wire [7:0]               arreq_len,
    input  wire [2:0]               arreq_size,
    input  wire [1:0]               arreq_burst,

    input  wire                     awreq_valid,
    input  wire [ID_WIDTH-1:0]      awreq_id,
    input  wire [ADDR_WIDTH-1:0]    awreq_addr,
    input  wire [7:0]               awreq_len,
    input  wire [2:0]               awreq_size,
    input  wire [1:0]               awreq_burst,

    input  wire                     wreq_valid,
    input  wire [DATA_WIDTH-1:0]    wreq_data,
    input  wire [DATA_WIDTH/8-1:0]  wreq_strb,
    input  wire                     wreq_last,

    input  wire                     breq_valid,
    input  wire [ID_WIDTH-1:0]      breq_id,

    input  wire                     rreq_valid,
    input  wire [ID_WIDTH-1:0]      rreq_id,

    output reg  [DATA_WIDTH-1:0]    rresp_data,
    output reg                      rresp_last

);

    integer handle, result;

    initial begin
        handle = $rammodel_new(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, MEM_SIZE);
        if (handle == -1) begin
            $display("ERROR: rammodel internal error");
            $fatal;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            result = $rammodel_reset(handle);
            if (!result) begin
                $display("ERROR: rammodel internal error");
                $fatal;
            end
        end
        else begin
            if (arreq_valid) begin
                result = $rammodel_ar_push(handle, arreq_id, arreq_addr, arreq_len, arreq_size, arreq_burst);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
            if (awreq_valid) begin
                result = $rammodel_aw_push(handle, awreq_id, awreq_addr, awreq_len, awreq_size, awreq_burst);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
            if (wreq_valid) begin
                result = $rammodel_w_push(handle, wreq_data, wreq_strb, wreq_last);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
            if (breq_valid) begin
                result = $rammodel_b_pop(handle, breq_id);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
            if (rreq_valid) begin
                result = $rammodel_r_pop(handle, rreq_id);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
        end
        result = $rammodel_b_front(handle, breq_id);
        if (!result) begin
            $display("ERROR: rammodel internal error");
            $fatal;
        end
        result = $rammodel_r_front(handle, rreq_id, rresp_data, rresp_last);
        if (!result) begin
            $display("ERROR: rammodel internal error");
            $fatal;
        end
    end

endmodule
