module FIFOAXI4Ctrl #(
    parameter REGADDR_WRITEMODE = 0,
    parameter REGADDR_BASEADDR_L = 4,
    parameter REGADDR_BASEADDR_H = 8,
    parameter CTRL_ADDR_WIDTH = 16,
    parameter AXI_ADDR_WIDTH  = 36,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_STRB_WIDTH  = (AXI_DATA_WIDTH/8),
    parameter AXI_ID_WIDTH    = 4,
    parameter AXI_BUSER_WIDTH = 0,
    parameter AXI_WUSER_WIDTH = 0,
    parameter AXI_AWUSER_WIDTH = 0
) (
    input  wire                       clk,
    input  wire                       rst,
    input  wire                       ctrl_wen,
    input  wire [CTRL_ADDR_WIDTH-1:0] ctrl_waddr,
    input  wire [               31:0] ctrl_wdata,
    input  wire                       ctrl_ren,
    input  wire [CTRL_ADDR_WIDTH-1:0] ctrl_raddr,
    output reg  [               31:0] ctrl_rdata,
    // TODO: add fifo size to support burst
    // input  wire                  ibusrt, 
    input  wire                       ivalid,
    input  wire [ AXI_DATA_WIDTH-1:0] idata,
    output wire                       iready,

    /*
     * AXI master interface
     */
    output wire [    AXI_ID_WIDTH-1:0] m_axi_awid,
    output wire [  AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output wire [                 7:0] m_axi_awlen,
    output wire [                 2:0] m_axi_awsize,
    output wire [                 1:0] m_axi_awburst,
    output wire                        m_axi_awlock,
    output wire [                 3:0] m_axi_awcache,
    output wire [                 2:0] m_axi_awprot,
    output wire [                 3:0] m_axi_awqos,
    output wire [                 3:0] m_axi_awregion,
    output wire [AXI_AWUSER_WIDTH-1:0] m_axi_awuser,
    output wire                        m_axi_awvalid,
    input  wire                        m_axi_awready,
    output wire [  AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output wire [  AXI_STRB_WIDTH-1:0] m_axi_wstrb,
    output wire                        m_axi_wlast,
    output wire [ AXI_WUSER_WIDTH-1:0] m_axi_wuser,
    output wire                        m_axi_wvalid,
    input  wire                        m_axi_wready,
    input  wire [    AXI_ID_WIDTH-1:0] m_axi_bid,
    input  wire [                 1:0] m_axi_bresp,
    input  wire [ AXI_BUSER_WIDTH-1:0] m_axi_buser,
    input  wire                        m_axi_bvalid,
    output wire                        m_axi_bready
);
  localparam WRITE_MODE_WRAP = 'd1;
  localparam WRITE_MODE_STOP = 'd0;
  localparam WRITE_MODE_RST = 'd0;
  localparam BASE_ADDR_DEFAULT = 'd0;
  reg [1:0] writeMode;
  reg [AXI_ADDR_WIDTH-1:0] baseAddr;
  // ==============================================
  // ============== ctrl write ====================
  // ==============================================
  always @(posedge clk) begin
    if (rst) begin
      baseAddr  <= BASE_ADDR_DEFAULT;
      writeMode <= WRITE_MODE_RST;
    end else if (ctrl_wen) begin
      if (ctrl_waddr == REGADDR_BASEADDR_L) begin
        baseAddr[31:0] <= ctrl_wdata;
      end
      if (ctrl_waddr == REGADDR_BASEADDR_H) begin
        baseAddr[AXI_ADDR_WIDTH-1:32] <= ctrl_wdata[AXI_ADDR_WIDTH-32-1:0];
      end
      if (ctrl_waddr == REGADDR_WRITEMODE) begin
        writeMode <= ctrl_wdata[1:0];
      end
    end
  end
  // ==============================================
  // ============== ctrl read =====================
  // ==============================================
  always @(posedge clk) begin
    if (ctrl_ren) begin
      if (ctrl_raddr == REGADDR_WRITEMODE) begin
        ctrl_rdata <= (writeMode | 32'd0);
      end
      if (ctrl_raddr == REGADDR_BASEADDR_L) begin
        ctrl_rdata <= baseAddr[31:0];
      end
      if (ctrl_raddr == REGADDR_BASEADDR_H) begin
        ctrl_rdata <= (baseAddr[AXI_ADDR_WIDTH-1:32] | 32'd0);
      end
    end
  end

  // FIFO to AXI
  localparam WRITE_OFFSET_MAX = 1024 * 1024 * 1024;
  reg [AXI_ADDR_WIDTH-1:0] writeOffset;
  always @(posedge clk) begin
    if (rst) begin
      writeOffset <= 'd0;
    end else if (m_axi_awvalid && m_axi_awready) begin
      // wrap mode and stop mode will not write other place
      writeOffset <= (writeOffset + AXI_DATA_WIDTH / 8) & (WRITE_OFFSET_MAX - 1);
    end
  end
  assign m_axi_awaddr = baseAddr + writeOffset;
  assign m_axi_awid = 0;
  assign m_axi_awlen = 0;
  assign m_axi_awburst = 1;  //INCR
  assign m_axi_awsize = $clog2(AXI_DATA_WIDTH);
  assign m_axi_awlock = 0;
  assign m_axi_awprot = 0;
  assign m_axi_awuser = 0;
  assign m_axi_awcache = 0;
  assign m_axi_awqos = 0;
  assign m_axi_wstrb = ~0;
  assign m_axi_wlast = 1;
  assign m_axi_bready = 1;

  reg [AXI_DATA_WIDTH-1:0] bufferData;
  reg bufferBusy;
  reg awFire;
  reg wFire;
  always @(posedge clk) begin
    if (rst) begin
      bufferBusy <= 0;
    end
    if (ivalid && iready) begin
      bufferData <= idata;
      bufferBusy <= 1;
    end else if (awFire && wFire) begin
      bufferBusy <= 0;
    end
  end
  always @(posedge clk) begin
    if (ivalid && iready) begin
      awFire <= 0;
      wFire  <= 0;
    end else if (m_axi_awvalid && m_axi_awready) begin
      awFire <= 1;
    end else if (m_axi_wvalid && m_axi_wready) begin
      wFire <= 1;
    end
  end
  assign m_axi_wdata   = bufferData;
  assign m_axi_awvalid = bufferBusy;
  assign m_axi_wvalid  = bufferBusy;
  wire writeOffsetMax = (writeOffset == WRITE_OFFSET_MAX) && writeMode == WRITE_MODE_STOP;
  assign iready = !bufferBusy && !writeOffsetMax;
endmodule
