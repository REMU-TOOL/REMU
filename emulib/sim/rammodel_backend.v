`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module emulib_rammodel_backend #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MEM_SIZE        = 64'h10000000,
    parameter   MAX_INFLIGHT    = 8
)(

    input  wire                     clk,
    input  wire                     rst,

    input  wire                     areq_valid,
    input  wire                     areq_write,
    input  wire [ID_WIDTH-1:0]      areq_id,
    input  wire [ADDR_WIDTH-1:0]    areq_addr,
    input  wire [7:0]               areq_len,
    input  wire [2:0]               areq_size,
    input  wire [1:0]               areq_burst,

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

    always @(clk, breq_valid, breq_id) begin
        if (!rst && breq_valid) begin
            result = $rammodel_b_req(handle, breq_id);
            if (!result) begin
                $display("ERROR: rammodel internal error");
                $fatal;
            end
        end
    end

    always @(clk, rreq_valid, rreq_id) begin
        if (!rst && rreq_valid) begin
            result = $rammodel_r_req(handle, rreq_id, rresp_data, rresp_last);
            if (!result) begin
                $display("ERROR: rammodel internal error");
                $fatal;
            end
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
            if (areq_valid) begin
                result = $rammodel_a_req(handle, areq_id, areq_addr, areq_len, areq_size, areq_burst, areq_write);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
            if (wreq_valid) begin
                result = $rammodel_w_req(handle, wreq_data, wreq_strb, wreq_last);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
            if (breq_valid) begin
                result = $rammodel_b_ack(handle);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
            if (rreq_valid) begin
                result = $rammodel_r_ack(handle);
                if (!result) begin
                    $display("ERROR: rammodel internal error");
                    $fatal;
                end
            end
        end
    end

endmodule
