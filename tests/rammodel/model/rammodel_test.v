`timescale 1ns / 1ps

`include "axi.vh"
`include "axi_custom.vh"

module EmuRamTest #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MEM_SIZE        = 64'h10000,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8,
    parameter   R_DELAY         = 100,
    parameter   W_DELAY         = 100
)(
    input                       host_clk,
    input                       host_rst,

    output                      target_clk,
    input                       target_rst,

    `AXI4_SLAVE_IF              (s_axi,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (host_axi,  ADDR_WIDTH, DATA_WIDTH, 1),

    input                       run_mode,
    output                      idle
);

    localparam   TIMING_TYPE     = "fixed";

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

        .clk                    (target_clk),
        .rst                    (target_rst),

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

    wire finishing;
    wire tick = run_mode && finishing;
    ClockGate clk_gate(
        .CLK(host_clk),
        .EN(tick),
        .OCLK(target_clk)
    );

    integer target_cnt = 0;
    always @(posedge target_clk) target_cnt <= target_cnt + 1;
    reg tk_rst_done;
    wire tk_rst_valid   = !tk_rst_done && run_mode;
    wire tk_rst_ready   ;
    wire tk_rst_fire    = tk_rst_valid && tk_rst_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_rst_done <= 1'b0;
        else if (tk_rst_fire)
            tk_rst_done <= 1'b1;

    reg tk_arreq_done;
    wire tk_arreq_valid  = !tk_arreq_done && run_mode;
    wire tk_arreq_ready  ;
    wire tk_arreq_fire   = tk_arreq_valid && tk_arreq_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_arreq_done <= 1'b0;
        else if (tk_arreq_fire)
            tk_arreq_done <= 1'b1;

    reg tk_awreq_done;
    wire tk_awreq_valid  = !tk_awreq_done && run_mode;
    wire tk_awreq_ready  ;
    wire tk_awreq_fire   = tk_awreq_valid && tk_awreq_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_awreq_done <= 1'b0;
        else if (tk_awreq_fire)
            tk_awreq_done <= 1'b1;

    reg tk_wreq_done;
    wire tk_wreq_valid  = !tk_wreq_done && run_mode;
    wire tk_wreq_ready  ;
    wire tk_wreq_fire   = tk_wreq_valid && tk_wreq_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_wreq_done <= 1'b0;
        else if (tk_wreq_fire)
            tk_wreq_done <= 1'b1;

    reg tk_breq_done;
    wire tk_breq_valid  = !tk_breq_done && run_mode;
    wire tk_breq_ready  ;
    wire tk_breq_fire   = tk_breq_valid && tk_breq_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_breq_done <= 1'b0;
        else if (tk_breq_fire)
            tk_breq_done <= 1'b1;

    reg tk_rreq_done;
    wire tk_rreq_valid  = !tk_rreq_done && run_mode;
    wire tk_rreq_ready  ;
    wire tk_rreq_fire   = tk_rreq_valid && tk_rreq_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_rreq_done <= 1'b0;
        else if (tk_rreq_fire)
            tk_rreq_done <= 1'b1;

    reg tk_bresp_done;
    wire tk_bresp_valid ;
    wire tk_bresp_ready = !tk_bresp_done && run_mode;
    wire tk_bresp_fire  = tk_bresp_valid && tk_bresp_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_bresp_done <= 1'b0;
        else if (tk_bresp_fire)
            tk_bresp_done <= 1'b1;

    reg tk_rresp_done;
    wire tk_rresp_valid ;
    wire tk_rresp_ready = !tk_rresp_done && run_mode;
    wire tk_rresp_fire  = tk_rresp_valid && tk_rresp_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_rresp_done <= 1'b0;
        else if (tk_rresp_fire)
            tk_rresp_done <= 1'b1;

    assign finishing = &{
        tk_rst_fire || tk_rst_done,
        tk_arreq_fire || tk_arreq_done,
        tk_awreq_fire || tk_awreq_done,
        tk_wreq_fire || tk_wreq_done,
        tk_breq_fire || tk_breq_done,
        tk_rreq_fire || tk_rreq_done,
        tk_bresp_fire || tk_bresp_done,
        tk_rresp_fire || tk_rresp_done
    };

    wire [DATA_WIDTH-1:0]    rresp_data_raw;
    wire                     rresp_last_raw;

    reg  [DATA_WIDTH-1:0]    rresp_data_r;
    reg                      rresp_last_r;

    always @(posedge host_clk) begin
        if (tk_rresp_fire) begin
            rresp_data_r <= rresp_data_raw;
            rresp_last_r <= rresp_last_raw;
        end
    end

    assign rresp_data = tk_rresp_done ? rresp_data_r : rresp_data_raw;
    assign rresp_last = tk_rresp_done ? rresp_last_r : rresp_last_raw;

    emulib_rammodel_backend #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .MEM_SIZE       (MEM_SIZE),
        .MAX_R_INFLIGHT (MAX_R_INFLIGHT),
        .MAX_W_INFLIGHT (MAX_W_INFLIGHT)
    )
    backend (

        .mdl_clk(host_clk),
        .mdl_rst(host_rst),

        .clk                    (target_clk),

        .tk_rst_valid(tk_rst_valid),
        .tk_rst_ready(tk_rst_ready),

        .rst                    (target_rst),

        .tk_arreq_valid(tk_arreq_valid),
        .tk_arreq_ready(tk_arreq_ready),

        .arreq_valid            (arreq_valid),
        .arreq_id               (arreq_id),
        .arreq_addr             (arreq_addr),
        .arreq_len              (arreq_len),
        .arreq_size             (arreq_size),
        .arreq_burst            (arreq_burst),

        .tk_awreq_valid(tk_awreq_valid),
        .tk_awreq_ready(tk_awreq_ready),

        .awreq_valid            (awreq_valid),
        .awreq_id               (awreq_id),
        .awreq_addr             (awreq_addr),
        .awreq_len              (awreq_len),
        .awreq_size             (awreq_size),
        .awreq_burst            (awreq_burst),

        .tk_wreq_valid(tk_wreq_valid),
        .tk_wreq_ready(tk_wreq_ready),

        .wreq_valid             (wreq_valid),
        .wreq_data              (wreq_data),
        .wreq_strb              (wreq_strb),
        .wreq_last              (wreq_last),

        .tk_breq_valid(tk_breq_valid),
        .tk_breq_ready(tk_breq_ready),

        .breq_valid             (breq_valid),
        .breq_id                (breq_id),

        .tk_rreq_valid(tk_rreq_valid),
        .tk_rreq_ready(tk_rreq_ready),

        .rreq_valid             (rreq_valid),
        .rreq_id                (rreq_id),

        .tk_bresp_valid(tk_bresp_valid),
        .tk_bresp_ready(tk_bresp_ready),

        .tk_rresp_valid(tk_rresp_valid),
        .tk_rresp_ready(tk_rresp_ready),

        .rresp_data             (rresp_data_raw),
        .rresp_last             (rresp_last_raw),

        `AXI4_CONNECT_NO_ID     (host_axi, host_axi),

        .run_mode(run_mode),
        .scan_mode(1'b0),
        .idle(idle)

    );

    assign frontend.timing_model.fixed.inst.cfg.r_delay = R_DELAY;
    assign frontend.timing_model.fixed.inst.cfg.w_delay = W_DELAY;

    assign host_axi_awid = 0;
    assign host_axi_arid = 0;

endmodule
