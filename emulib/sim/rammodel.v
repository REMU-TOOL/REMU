`timescale 1ns / 1ps

`include "axi.vh"

(* keep *)
module EmuRam #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h10000,
    parameter   MAX_INFLIGHT    = 8,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input  wire                 clk,
    input  wire                 rst,

    `AXI4_SLAVE_IF              (s_axi,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH)

);

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
    reg  [DATA_WIDTH-1:0]    rreq_data;
    reg                      rreq_last;

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
        .rreq_data              (rreq_data),
        .rreq_last              (rreq_last)

    );

    integer handle, result;

    initial begin
        handle = $rammodel_new(ADDR_WIDTH, DATA_WIDTH, ID_WIDTH, PF_COUNT);
        if (handle == -1) begin
            $display("ERROR: rammodel internal error");
            $fatal;
        end
    end

    always @(clk, breq_valid) begin
        if (!rst && breq_valid) begin
            result = $rammodel_b_req(handle, breq_id);
            if (!result) begin
                $display("ERROR: rammodel internal error");
                $fatal;
            end
        end
    end

    always @(clk, rreq_valid) begin
        if (!rst && rreq_valid) begin
            result = $rammodel_r_req(handle, rreq_id, rreq_data, rreq_last);
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
