`timescale 1ns / 1ps

`include "axi.vh"

module rammodel_test #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h1
)(
    input                       host_clk,
    input                       host_rst,

    output                      target_clk,
    input                       target_rst,

    `AXI4_SLAVE_IF              (s_axi,     ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (host_axi,  ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),
    `AXI4_MASTER_IF             (lsu_axi, 32, 32, 1),

    input                       run_mode,
    output                      finishing,

    input                       up_req,
    input                       down_req,
    output                      up,
    output                      down
);

    wire tick = run_mode && finishing;
    ClockGate clk_gate(
        .CLK(host_clk),
        .EN(tick),
        .OCLK(target_clk)
    );

    integer target_cnt = 0;
    always @(posedge target_clk) target_cnt <= target_cnt + 1;

    EmuRam #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .PF_COUNT   (PF_COUNT)
    )
    uut (
        .clk            (target_clk),
        .rst            (target_rst),
        `AXI4_CONNECT   (s_axi, s_axi)
    );

    reg tk_rst_done;
    wire tk_rst_valid   = !tk_rst_done && run_mode;
    wire tk_rst_ready   = uut.backend.tk_rst_ready;
    wire tk_rst_fire    = tk_rst_valid && tk_rst_ready;
    assign uut.backend.tk_rst_valid = tk_rst_valid;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_rst_done <= 1'b0;
        else if (tk_rst_fire)
            tk_rst_done <= 1'b1;

    reg tk_areq_done;
    wire tk_areq_valid  = !tk_areq_done && run_mode;
    wire tk_areq_ready  = uut.backend.tk_areq_ready;
    wire tk_areq_fire   = tk_areq_valid && tk_areq_ready;
    assign uut.backend.tk_areq_valid = tk_areq_valid;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_areq_done <= 1'b0;
        else if (tk_areq_fire)
            tk_areq_done <= 1'b1;

    reg tk_wreq_done;
    wire tk_wreq_valid  = !tk_wreq_done && run_mode;
    wire tk_wreq_ready  = uut.backend.tk_wreq_ready;
    wire tk_wreq_fire   = tk_areq_valid && tk_wreq_ready;
    assign uut.backend.tk_wreq_valid = tk_wreq_valid;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_wreq_done <= 1'b0;
        else if (tk_wreq_fire)
            tk_wreq_done <= 1'b1;

    reg tk_breq_done;
    wire tk_breq_valid  = !tk_breq_done && run_mode;
    wire tk_breq_ready  = uut.backend.tk_breq_ready;
    wire tk_breq_fire   = tk_breq_valid && tk_breq_ready;
    assign uut.backend.tk_breq_valid = tk_breq_valid;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_breq_done <= 1'b0;
        else if (tk_breq_fire)
            tk_breq_done <= 1'b1;

    reg tk_rreq_done;
    wire tk_rreq_valid  = !tk_rreq_done && run_mode;
    wire tk_rreq_ready  = uut.backend.tk_rreq_ready;
    wire tk_rreq_fire   = tk_rreq_valid && tk_rreq_ready;
    assign uut.backend.tk_rreq_valid = tk_rreq_valid;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_rreq_done <= 1'b0;
        else if (tk_rreq_fire)
            tk_rreq_done <= 1'b1;

    reg tk_bresp_done;
    wire tk_bresp_valid = uut.backend.tk_bresp_valid;
    wire tk_bresp_ready = !tk_bresp_done && run_mode;
    wire tk_bresp_fire  = tk_bresp_valid && tk_bresp_ready;
    assign uut.backend.tk_bresp_ready = tk_bresp_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_bresp_done <= 1'b0;
        else if (tk_bresp_fire)
            tk_bresp_done <= 1'b1;

    reg tk_rresp_done;
    wire tk_rresp_valid = uut.backend.tk_rresp_valid;
    wire tk_rresp_ready = !tk_rresp_done && run_mode;
    wire tk_rresp_fire  = tk_rresp_valid && tk_rresp_ready;
    assign uut.backend.tk_rresp_ready = tk_rresp_ready;

    always @(posedge host_clk)
        if (host_rst || tick)
            tk_rresp_done <= 1'b0;
        else if (tk_rresp_fire)
            tk_rresp_done <= 1'b1;

    assign finishing = &{
        tk_rst_fire || tk_rst_done,
        tk_areq_fire || tk_areq_done,
        tk_wreq_fire || tk_wreq_done,
        tk_breq_fire || tk_breq_done,
        tk_rreq_fire || tk_rreq_done,
        tk_bresp_fire || tk_bresp_done,
        tk_rresp_fire || tk_rresp_done
    };

    assign uut.backend.mdl_clk  = host_clk;
    assign uut.backend.mdl_rst  = host_rst;
    assign uut.backend.up_req   = up_req;
    assign uut.backend.down_req = down_req;
    assign up                   = uut.backend.up_ack;
    assign down                 = uut.backend.down_ack;

    assign  /**********/    host_axi_awvalid    =   uut.backend.    host_axi_awvalid;
    assign  uut.backend.    host_axi_awready    =   /**********/    host_axi_awvalid;
    assign  /**********/    host_axi_awaddr     =   uut.backend.    host_axi_awaddr;
    assign  /**********/    host_axi_awid       =   uut.backend.    host_axi_awid;
    assign  /**********/    host_axi_awlen      =   uut.backend.    host_axi_awlen;
    assign  /**********/    host_axi_awsize     =   uut.backend.    host_axi_awsize;
    assign  /**********/    host_axi_awburst    =   uut.backend.    host_axi_awburst;
    assign  /**********/    host_axi_awlock     =   uut.backend.    host_axi_awlock;
    assign  /**********/    host_axi_awcache    =   uut.backend.    host_axi_awcache;
    assign  /**********/    host_axi_awprot     =   uut.backend.    host_axi_awprot;
    assign  /**********/    host_axi_awqos      =   uut.backend.    host_axi_awqos;
    assign  /**********/    host_axi_awregion   =   uut.backend.    host_axi_awregion;
    assign  /**********/    host_axi_wvalid     =   uut.backend.    host_axi_wvalid;
    assign  uut.backend.    host_axi_wready     =   /**********/    host_axi_wready;
    assign  /**********/    host_axi_wdata      =   uut.backend.    host_axi_wdata;
    assign  /**********/    host_axi_wstrb      =   uut.backend.    host_axi_wstrb;
    assign  /**********/    host_axi_wlast      =   uut.backend.    host_axi_wlast;
    assign  uut.backend.    host_axi_bvalid     =   /**********/    host_axi_bvalid;
    assign  /**********/    host_axi_bready     =   uut.backend.    host_axi_bready;
    assign  uut.backend.    host_axi_bresp      =   /**********/    host_axi_bresp;
    assign  uut.backend.    host_axi_bid        =   /**********/    host_axi_bid;
    assign  /**********/    host_axi_arvalid    =   uut.backend.    host_axi_arvalid;
    assign  uut.backend.    host_axi_arready    =   /**********/    host_axi_arready;
    assign  /**********/    host_axi_araddr     =   uut.backend.    host_axi_araddr;
    assign  /**********/    host_axi_arid       =   uut.backend.    host_axi_arid;
    assign  /**********/    host_axi_arlen      =   uut.backend.    host_axi_arlen;
    assign  /**********/    host_axi_arsize     =   uut.backend.    host_axi_arsize;
    assign  /**********/    host_axi_arburst    =   uut.backend.    host_axi_arburst;
    assign  /**********/    host_axi_arlock     =   uut.backend.    host_axi_arlock;
    assign  /**********/    host_axi_arcache    =   uut.backend.    host_axi_arcache;
    assign  /**********/    host_axi_arprot     =   uut.backend.    host_axi_arprot;
    assign  /**********/    host_axi_arqos      =   uut.backend.    host_axi_arqos;
    assign  /**********/    host_axi_arregion   =   uut.backend.    host_axi_arregion;
    assign  uut.backend.    host_axi_rvalid     =   /**********/    host_axi_rvalid;
    assign  /**********/    host_axi_rready     =   uut.backend.    host_axi_rready;
    assign  uut.backend.    host_axi_rdata      =   /**********/    host_axi_rdata;
    assign  uut.backend.    host_axi_rresp      =   /**********/    host_axi_rresp;
    assign  uut.backend.    host_axi_rid        =   /**********/    host_axi_rid;
    assign  uut.backend.    host_axi_rlast      =   /**********/    host_axi_rlast;

    assign  /**********/    lsu_axi_awvalid     =   uut.backend.    lsu_axi_awvalid;
    assign  uut.backend.    lsu_axi_awready     =   /**********/    lsu_axi_awready;
    assign  /**********/    lsu_axi_awaddr      =   uut.backend.    lsu_axi_awaddr;
    assign  /**********/    lsu_axi_awlen       =   uut.backend.    lsu_axi_awlen;
    assign  /**********/    lsu_axi_awsize      =   uut.backend.    lsu_axi_awsize;
    assign  /**********/    lsu_axi_awburst     =   uut.backend.    lsu_axi_awburst;
    assign  /**********/    lsu_axi_awlock      =   uut.backend.    lsu_axi_awlock;
    assign  /**********/    lsu_axi_awcache     =   uut.backend.    lsu_axi_awcache;
    assign  /**********/    lsu_axi_awprot      =   uut.backend.    lsu_axi_awprot;
    assign  /**********/    lsu_axi_awqos       =   uut.backend.    lsu_axi_awqos;
    assign  /**********/    lsu_axi_awregion    =   uut.backend.    lsu_axi_awregion;
    assign  /**********/    lsu_axi_wvalid      =   uut.backend.    lsu_axi_wvalid;
    assign  uut.backend.    lsu_axi_wready      =   /**********/    lsu_axi_wready;
    assign  /**********/    lsu_axi_wdata       =   uut.backend.    lsu_axi_wdata;
    assign  /**********/    lsu_axi_wstrb       =   uut.backend.    lsu_axi_wstrb;
    assign  /**********/    lsu_axi_wlast       =   uut.backend.    lsu_axi_wlast;
    assign  uut.backend.    lsu_axi_bvalid      =   /**********/    lsu_axi_bvalid;
    assign  /**********/    lsu_axi_bready      =   uut.backend.    lsu_axi_bready;
    assign  uut.backend.    lsu_axi_bresp       =   /**********/    lsu_axi_bresp;
    assign  /**********/    lsu_axi_arvalid     =   uut.backend.    lsu_axi_arvalid;
    assign  uut.backend.    lsu_axi_arready     =   /**********/    lsu_axi_arready;
    assign  /**********/    lsu_axi_araddr      =   uut.backend.    lsu_axi_araddr;
    assign  /**********/    lsu_axi_arlen       =   uut.backend.    lsu_axi_arlen;
    assign  /**********/    lsu_axi_arsize      =   uut.backend.    lsu_axi_arsize;
    assign  /**********/    lsu_axi_arburst     =   uut.backend.    lsu_axi_arburst;
    assign  /**********/    lsu_axi_arlock      =   uut.backend.    lsu_axi_arlock;
    assign  /**********/    lsu_axi_arcache     =   uut.backend.    lsu_axi_arcache;
    assign  /**********/    lsu_axi_arprot      =   uut.backend.    lsu_axi_arprot;
    assign  /**********/    lsu_axi_arqos       =   uut.backend.    lsu_axi_arqos;
    assign  /**********/    lsu_axi_arregion    =   uut.backend.    lsu_axi_arregion;
    assign  uut.backend.    lsu_axi_rvalid      =   /**********/    lsu_axi_rvalid;
    assign  /**********/    lsu_axi_rready      =   uut.backend.    lsu_axi_rready;
    assign  uut.backend.    lsu_axi_rdata       =   /**********/    lsu_axi_rdata;
    assign  uut.backend.    lsu_axi_rresp       =   /**********/    lsu_axi_rresp;
    assign  uut.backend.    lsu_axi_rlast       =   /**********/    lsu_axi_rlast;

    assign lsu_axi_arid = 0;
    assign lsu_axi_awid = 0;

endmodule
