# Emulation Models

## EmuClock

This model generates a global clock for DUT use. All clocks signals in DUT **must** be driven by an EmuClock instance.

### Prototype

```verilog
module EmuClock (
    output clock
);

endmodule
```

## EmuReset

This model generates a global reset for DUT use. The value of the reset signal is controlled by the monitor software.

### Prototype

```verilog
module EmuReset (
    output reset
);

endmodule
```

### EmuTrigger

This model provides a sink point for a trigger signal. If a trigger is active (high), emulation will pause in the next cycle.

### Prototype

```verilog
module EmuTrigger(
    input trigger
);

endmodule
```

## EmuRam

This model emulates a memory with AXI interface. The read/write latency can be configured via the parameters.

### Prototype

```verilog
module EmuRam #(
    parameter   ADDR_WIDTH      = 32,
    parameter   DATA_WIDTH      = 64,
    parameter   ID_WIDTH        = 4,
    parameter   PF_COUNT        = 'h10000,
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

## EmuPutChar

This model provides a sink point for console output. All valid data will be interpreted as chars and printed to the console.

### Prototype

```verilog
module EmuTrigger(
    input         clk,
    input         rst,
    input         valid,
    input [7:0]   data
);

endmodule
```
