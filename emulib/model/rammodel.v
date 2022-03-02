`resetall
`timescale 1ns / 1ps
`default_nettype none

`include "axi.vh"
`include "axi_a.vh"

(* keep, emulib_component = "rammodel" *)
module RAMModel #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h10000,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input  wire                     clk,
    input  wire                     rst,

    input  wire                     s_axi_awvalid,
    output wire                     s_axi_awready,
    input  wire [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire [ID_WIDTH-1:0]      s_axi_awid,
    input  wire [7:0]               s_axi_awlen,
    input  wire [2:0]               s_axi_awsize,
    input  wire [1:0]               s_axi_awburst,
    input  wire [0:0]               s_axi_awlock,
    input  wire [3:0]               s_axi_awcache,
    input  wire [2:0]               s_axi_awprot,
    input  wire [3:0]               s_axi_awqos,
    input  wire [3:0]               s_axi_awregion,

    input  wire                     s_axi_wvalid,
    output wire                     s_axi_wready,
    input  wire [DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input  wire                     s_axi_wlast,

    output wire                     s_axi_bvalid,
    input  wire                     s_axi_bready,
    output wire [1:0]               s_axi_bresp,
    output wire [ID_WIDTH-1:0]      s_axi_bid,

    input  wire                     s_axi_arvalid,
    output wire                     s_axi_arready,
    input  wire [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire [ID_WIDTH-1:0]      s_axi_arid,
    input  wire [7:0]               s_axi_arlen,
    input  wire [2:0]               s_axi_arsize,
    input  wire [1:0]               s_axi_arburst,
    input  wire [0:0]               s_axi_arlock,
    input  wire [3:0]               s_axi_arcache,
    input  wire [2:0]               s_axi_arprot,
    input  wire [3:0]               s_axi_arqos,
    input  wire [3:0]               s_axi_arregion,

    output wire                     s_axi_rvalid,
    input  wire                     s_axi_rready,
    output wire [DATA_WIDTH-1:0]    s_axi_rdata,
    output wire [1:0]               s_axi_rresp,
    output wire [ID_WIDTH-1:0]      s_axi_rid,
    output wire                     s_axi_rlast

);

    (* keep, emu_intf_port = "clk"              *) wire model_clk;
    (* keep, emu_intf_port = "rst"              *) wire model_rst;
    (* keep, emu_intf_port = "target_fire"      *) wire target_fire;
    (* keep, emu_intf_port = "stall"            *) wire stall;
    (* keep, emu_intf_port = "up_req"           *) wire up_req;
    (* keep, emu_intf_port = "down_req"         *) wire down_req;
    (* keep, emu_intf_port = "up_stat"          *) wire up_stat;
    (* keep, emu_intf_port = "down_stat"        *) wire down_stat;

    (* keep, emu_intf_port = "dram_awvalid"     *)
    wire                        m_axi_awvalid;
    (* keep, emu_intf_port = "dram_awready"     *)
    wire                        m_axi_awready;
    (* keep, emu_intf_port = "dram_awaddr"      *)
    wire    [ADDR_WIDTH-1:0]    m_axi_awaddr;
    (* keep, emu_intf_port = "dram_awid"        *)
    wire    [ID_WIDTH-1:0]      m_axi_awid;
    (* keep, emu_intf_port = "dram_awlen"       *)
    wire    [7:0]               m_axi_awlen;
    (* keep, emu_intf_port = "dram_awsize"      *)
    wire    [2:0]               m_axi_awsize;
    (* keep, emu_intf_port = "dram_awburst"     *)
    wire    [1:0]               m_axi_awburst;
    (* keep, emu_intf_port = "dram_awlock"      *)
    wire    [0:0]               m_axi_awlock;
    (* keep, emu_intf_port = "dram_awcache"     *)
    wire    [3:0]               m_axi_awcache;
    (* keep, emu_intf_port = "dram_awprot"      *)
    wire    [2:0]               m_axi_awprot;
    (* keep, emu_intf_port = "dram_awqos"       *)
    wire    [3:0]               m_axi_awqos;
    (* keep, emu_intf_port = "dram_awregion"    *)
    wire    [3:0]               m_axi_awregion;

    (* keep, emu_intf_port = "dram_wvalid"      *)
    wire                        m_axi_wvalid;
    (* keep, emu_intf_port = "dram_wready"      *)
    wire                        m_axi_wready;
    (* keep, emu_intf_port = "dram_wdata"       *)
    wire    [DATA_WIDTH-1:0]    m_axi_wdata;
    (* keep, emu_intf_port = "dram_wstrb"       *)
    wire    [DATA_WIDTH/8-1:0]  m_axi_wstrb;
    (* keep, emu_intf_port = "dram_wlast"       *)
    wire                        m_axi_wlast;

    (* keep, emu_intf_port = "dram_bvalid"      *)
    wire                        m_axi_bvalid;
    (* keep, emu_intf_port = "dram_bready"      *)
    wire                        m_axi_bready;
    (* keep, emu_intf_port = "dram_bresp"       *)
    wire    [1:0]               m_axi_bresp;
    (* keep, emu_intf_port = "dram_bid"         *)
    wire    [ID_WIDTH-1:0]      m_axi_bid;

    (* keep, emu_intf_port = "dram_arvalid"     *)
    wire                        m_axi_arvalid;
    (* keep, emu_intf_port = "dram_arready"     *)
    wire                        m_axi_arready;
    (* keep, emu_intf_port = "dram_araddr"      *)
    wire    [ADDR_WIDTH-1:0]    m_axi_araddr;
    (* keep, emu_intf_port = "dram_arid"        *)
    wire    [ID_WIDTH-1:0]      m_axi_arid;
    (* keep, emu_intf_port = "dram_arlen"       *)
    wire    [7:0]               m_axi_arlen;
    (* keep, emu_intf_port = "dram_arsize"      *)
    wire    [2:0]               m_axi_arsize;
    (* keep, emu_intf_port = "dram_arburst"     *)
    wire    [1:0]               m_axi_arburst;
    (* keep, emu_intf_port = "dram_arlock"      *)
    wire    [0:0]               m_axi_arlock;
    (* keep, emu_intf_port = "dram_arcache"     *)
    wire    [3:0]               m_axi_arcache;
    (* keep, emu_intf_port = "dram_arprot"      *)
    wire    [2:0]               m_axi_arprot;
    (* keep, emu_intf_port = "dram_arqos"       *)
    wire    [3:0]               m_axi_arqos;
    (* keep, emu_intf_port = "dram_arregion"    *)
    wire    [3:0]               m_axi_arregion;

    (* keep, emu_intf_port = "dram_rvalid"      *)
    wire                        m_axi_rvalid;
    (* keep, emu_intf_port = "dram_rready"      *)
    wire                        m_axi_rready;
    (* keep, emu_intf_port = "dram_rdata"       *)
    wire    [DATA_WIDTH-1:0]    m_axi_rdata;
    (* keep, emu_intf_port = "dram_rresp"       *)
    wire    [1:0]               m_axi_rresp;
    (* keep, emu_intf_port = "dram_rid"         *)
    wire    [ID_WIDTH-1:0]      m_axi_rid;
    (* keep, emu_intf_port = "dram_rlast"       *)
    wire                        m_axi_rlast;

    EmuRam #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH),
        .R_DELAY    (R_DELAY),
        .W_DELAY    (W_DELAY)
    )
    u_rammodel (
        .clk            (clk),
        .rst            (rst),
        `AXI4_CONNECT   (s_axi, s_axi),
        .host_clk       (model_clk),
        .host_rst       (model_rst),
        `AXI4_CONNECT   (host_axi, m_axi),
        .target_fire    (target_fire),
        .stall          (stall),
        .up_req         (up_req),
        .down_req       (down_req),
        .up_stat        (up_stat),
        .down_stat      (down_stat)
    );

endmodule

(* __emu_directive_1 = "extern host_clk" *)
(* __emu_directive_2 = "extern host_rst" *)
(* __emu_directive_3 = "extern host_axi_*" *)
(* __emu_directive_4 = "extern target_fire" *)
(* __emu_directive_5 = "extern stall" *)
(* __emu_directive_6 = "extern up_req" *)
(* __emu_directive_7 = "extern down_req" *)
(* __emu_directive_8 = "extern up_stat" *)
(* __emu_directive_9 = "extern down_stat" *)

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

    `AXI4_SLAVE_IF              (s_axi,    ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input  wire                 host_clk,
    input  wire                 host_rst,

    `AXI4_MASTER_IF             (host_axi,      ADDR_WIDTH, DATA_WIDTH, ID_WIDTH),

    input  wire                 target_fire,
    output wire                 stall,

    input  wire                 up_req,
    input  wire                 down_req,
    output wire                 up_stat,
    output wire                 down_stat

);

    `AXI4_A_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_W_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_B_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);
    `AXI4_R_WIRE(f2b, ADDR_WIDTH, DATA_WIDTH, ID_WIDTH);

    wire                 rreq_valid;
    wire [ID_WIDTH-1:0]  rreq_id;

    wire                 breq_valid;
    wire [ID_WIDTH-1:0]  breq_id;

    emulib_rammodel_frontend #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .MAX_INFLIGHT   (MAX_INFLIGHT),
        .R_DELAY        (R_DELAY),
        .W_DELAY        (W_DELAY)
    )
    frontend (

        .target_clk     (clk),
        .target_rst     (rst),

        `AXI4_CONNECT   (target_axi, s_axi),

        `AXI4_A_CONNECT (backend, f2b),
        `AXI4_W_CONNECT (backend, f2b),
        `AXI4_B_CONNECT (backend, f2b),
        `AXI4_R_CONNECT (backend, f2b),

        .rreq_valid     (rreq_valid),
        .rreq_id        (rreq_id),

        .breq_valid     (breq_valid),
        .breq_id        (breq_id)

    );

    emulib_rammodel_backend #(
        .ADDR_WIDTH     (ADDR_WIDTH),
        .DATA_WIDTH     (DATA_WIDTH),
        .ID_WIDTH       (ID_WIDTH),
        .PF_COUNT       (PF_COUNT),
        .MAX_INFLIGHT   (MAX_INFLIGHT)
    )
    backend (

        .host_clk       (host_clk),
        .host_rst       (host_rst),

        .target_clk     (clk),
        .target_rst     (rst),

        `AXI4_A_CONNECT (frontend, f2b),
        `AXI4_W_CONNECT (frontend, f2b),
        `AXI4_B_CONNECT (frontend, f2b),
        `AXI4_R_CONNECT (frontend, f2b),

        .rreq_valid     (rreq_valid),
        .rreq_id        (rreq_id),

        .breq_valid     (breq_valid),
        .breq_id        (breq_id),

        `AXI4_CONNECT   (host_axi, host_axi),

        .target_fire    (target_fire),
        .stall          (stall),

        .up_req         (up_req),
        .down_req       (down_req),
        .up_stat        (up_stat),
        .down_stat      (down_stat)

    );

`ifdef SIM_LOG

    always @(posedge clk) begin
        if (!rst) begin
            if (f2b_avalid && f2b_aready) begin
                $display("[%0d ns] %m: f2b A", $time);
            end
            if (f2b_wvalid && f2b_wready) begin
                $display("[%0d ns] %m: f2b W", $time);
            end
            if (f2b_bvalid && f2b_bready) begin
                $display("[%0d ns] %m: f2b B", $time);
            end
            if (f2b_rvalid && f2b_rready) begin
                $display("[%0d ns] %m: f2b R", $time);
            end
            if (breq_valid) begin
                $display("[%0d ns] %m: f2b BReq", $time);
            end
            if (rreq_valid) begin
                $display("[%0d ns] %m: f2b RReq", $time);
            end
        end
    end

`endif

endmodule

`resetall
