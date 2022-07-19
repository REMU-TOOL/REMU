`timescale 1ns / 1ps

module emu_top #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4
)(

    (* __emu_extern_intf = "test" *)
    input                       s_axi_awvalid,
    (* __emu_extern_intf = "test" *)
    output                      s_axi_awready,
    (* __emu_extern_intf = "test" *)
    input   [ADDR_WIDTH-1:0]    s_axi_awaddr,
    (* __emu_extern_intf = "test" *)
    input   [ID_WIDTH-1:0]      s_axi_awid,
    (* __emu_extern_intf = "test" *)
    input   [7:0]               s_axi_awlen,
    (* __emu_extern_intf = "test" *)
    input   [2:0]               s_axi_awsize,
    (* __emu_extern_intf = "test" *)
    input   [1:0]               s_axi_awburst,
    (* __emu_extern_intf = "test" *)
    input   [0:0]               s_axi_awlock,
    (* __emu_extern_intf = "test" *)
    input   [3:0]               s_axi_awcache,
    (* __emu_extern_intf = "test" *)
    input   [2:0]               s_axi_awprot,
    (* __emu_extern_intf = "test" *)
    input   [3:0]               s_axi_awqos,
    (* __emu_extern_intf = "test" *)
    input   [3:0]               s_axi_awregion,

    (* __emu_extern_intf = "test" *)
    input                       s_axi_wvalid,
    (* __emu_extern_intf = "test" *)
    output                      s_axi_wready,
    (* __emu_extern_intf = "test" *)
    input   [DATA_WIDTH-1:0]    s_axi_wdata,
    (* __emu_extern_intf = "test" *)
    input   [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    (* __emu_extern_intf = "test" *)
    input                       s_axi_wlast,

    (* __emu_extern_intf = "test" *)
    output                      s_axi_bvalid,
    (* __emu_extern_intf = "test" *)
    input                       s_axi_bready,
    (* __emu_extern_intf = "test" *)
    output  [1:0]               s_axi_bresp,
    (* __emu_extern_intf = "test" *)
    output  [ID_WIDTH-1:0]      s_axi_bid,

    (* __emu_extern_intf = "test" *)
    input                       s_axi_arvalid,
    (* __emu_extern_intf = "test" *)
    output                      s_axi_arready,
    (* __emu_extern_intf = "test" *)
    input   [ADDR_WIDTH-1:0]    s_axi_araddr,
    (* __emu_extern_intf = "test" *)
    input   [ID_WIDTH-1:0]      s_axi_arid,
    (* __emu_extern_intf = "test" *)
    input   [7:0]               s_axi_arlen,
    (* __emu_extern_intf = "test" *)
    input   [2:0]               s_axi_arsize,
    (* __emu_extern_intf = "test" *)
    input   [1:0]               s_axi_arburst,
    (* __emu_extern_intf = "test" *)
    input   [0:0]               s_axi_arlock,
    (* __emu_extern_intf = "test" *)
    input   [3:0]               s_axi_arcache,
    (* __emu_extern_intf = "test" *)
    input   [2:0]               s_axi_arprot,
    (* __emu_extern_intf = "test" *)
    input   [3:0]               s_axi_arqos,
    (* __emu_extern_intf = "test" *)
    input   [3:0]               s_axi_arregion,

    (* __emu_extern_intf = "test" *)
    output                      s_axi_rvalid,
    (* __emu_extern_intf = "test" *)
    input                       s_axi_rready,
    (* __emu_extern_intf = "test" *)
    output  [DATA_WIDTH-1:0]    s_axi_rdata,
    (* __emu_extern_intf = "test" *)
    output  [1:0]               s_axi_rresp,
    (* __emu_extern_intf = "test" *)
    output  [ID_WIDTH-1:0]      s_axi_rid,
    (* __emu_extern_intf = "test" *)
    output                      s_axi_rlast

);

    wire clk, rst;
    EmuClock clock(.clock(clk));
    EmuReset reset(.reset(rst));

    EmuRam #(
        .ADDR_WIDTH (ADDR_WIDTH),
        .DATA_WIDTH (DATA_WIDTH),
        .ID_WIDTH   (ID_WIDTH)
    )
    u_rammodel (
        .clk            (clk),
        .rst            (rst),

        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),
        .s_axi_awaddr   (s_axi_awaddr),
        .s_axi_awid     (s_axi_awid),
        .s_axi_awlen    (s_axi_awlen),
        .s_axi_awsize   (s_axi_awsize),
        .s_axi_awburst  (s_axi_awburst),
        .s_axi_awlock   (s_axi_awlock),
        .s_axi_awcache  (s_axi_awcache),
        .s_axi_awprot   (s_axi_awprot),
        .s_axi_awqos    (s_axi_awqos),
        .s_axi_awregion (s_axi_awregion),

        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),
        .s_axi_wdata    (s_axi_wdata),
        .s_axi_wstrb    (s_axi_wstrb),
        .s_axi_wlast    (s_axi_wlast),

        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),
        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bid      (s_axi_bid),

        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (s_axi_arready),
        .s_axi_araddr   (s_axi_araddr),
        .s_axi_arid     (s_axi_arid),
        .s_axi_arlen    (s_axi_arlen),
        .s_axi_arsize   (s_axi_arsize),
        .s_axi_arburst  (s_axi_arburst),
        .s_axi_arlock   (s_axi_arlock),
        .s_axi_arcache  (s_axi_arcache),
        .s_axi_arprot   (s_axi_arprot),
        .s_axi_arqos    (s_axi_arqos),
        .s_axi_arregion (s_axi_arregion),

        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rready   (s_axi_rready),
        .s_axi_rdata    (s_axi_rdata),
        .s_axi_rresp    (s_axi_rresp),
        .s_axi_rid      (s_axi_rid),
        .s_axi_rlast    (s_axi_rlast)
    );

endmodule
