# Emulation Models

## EmuRam

This model emulates a memory with AXI interface. The read/write latency can be configured via the parameters.

### Prototype

```verilog
module EmuRam #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   MEM_SIZE        = 64'h10000000,
    parameter   MAX_INFLIGHT    = 8,
    parameter   R_DELAY         = 25,
    parameter   W_DELAY         = 3
)(

    input                      clk,
    input                      rst,

    input                      s_axi_awvalid,
    output                     s_axi_awready,
    input  [ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  [ID_WIDTH-1:0]      s_axi_awid,
    input  [7:0]               s_axi_awlen,
    input  [2:0]               s_axi_awsize,
    input  [1:0]               s_axi_awburst,
    input  [0:0]               s_axi_awlock,
    input  [3:0]               s_axi_awcache,
    input  [2:0]               s_axi_awprot,
    input  [3:0]               s_axi_awqos,
    input  [3:0]               s_axi_awregion,

    input                      s_axi_wvalid,
    output                     s_axi_wready,
    input  [DATA_WIDTH-1:0]    s_axi_wdata,
    input  [DATA_WIDTH/8-1:0]  s_axi_wstrb,
    input                      s_axi_wlast,

    output                     s_axi_bvalid,
    input                      s_axi_bready,
    output [1:0]               s_axi_bresp,
    output [ID_WIDTH-1:0]      s_axi_bid,

    input                      s_axi_arvalid,
    output                     s_axi_arready,
    input  [ADDR_WIDTH-1:0]    s_axi_araddr,
    input  [ID_WIDTH-1:0]      s_axi_arid,
    input  [7:0]               s_axi_arlen,
    input  [2:0]               s_axi_arsize,
    input  [1:0]               s_axi_arburst,
    input  [0:0]               s_axi_arlock,
    input  [3:0]               s_axi_arcache,
    input  [2:0]               s_axi_arprot,
    input  [3:0]               s_axi_arqos,
    input  [3:0]               s_axi_arregion,

    output                     s_axi_rvalid,
    input                      s_axi_rready,
    output [DATA_WIDTH-1:0]    s_axi_rdata,
    output [1:0]               s_axi_rresp,
    output [ID_WIDTH-1:0]      s_axi_rid,
    output                     s_axi_rlast

);

endmodule
```

## EmuUart

This model emulates the function of UART controller. The user can interact with this in a terminal console.

This model is compatible to Xilinx AXI UART-Lite.

### Prototype

```verilog
module EmuUart #(
    parameter   RX_FIFO_DEPTH   = 16,
    parameter   TX_FIFO_DEPTH   = 16
)(
    input  wire         clk,
    input  wire         rst,

    input  wire         s_axilite_awvalid,
    output wire         s_axilite_awready,
    input  wire [3:0]   s_axilite_awaddr,
    input  wire [2:0]   s_axilite_awprot,

    input  wire         s_axilite_wvalid,
    output wire         s_axilite_wready,
    input  wire [31:0]  s_axilite_wdata,
    input  wire [3:0]   s_axilite_wstrb,

    output wire         s_axilite_bvalid,
    input  wire         s_axilite_bready,
    output wire [1:0]   s_axilite_bresp,

    input  wire         s_axilite_arvalid,
    output wire         s_axilite_arready,
    input  wire [3:0]   s_axilite_araddr,
    input  wire [2:0]   s_axilite_arprot,

    output wire         s_axilite_rvalid,
    input  wire         s_axilite_rready,
    output wire [31:0]  s_axilite_rdata,
    output wire [1:0]   s_axilite_rresp
);

endmodule
```

### Register Space

TODO
