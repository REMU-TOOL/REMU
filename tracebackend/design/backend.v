module TraceBackend #(
    parameter CTRL_ADDR_WIDTH = 16,
    parameter AXI_ADDR_WIDTH = 36,
    parameter AXI_DATA_WIDTH = 64,
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_STRB_WIDTH  = (AXI_DATA_WIDTH/8),
    parameter AXI_AWUSER_WIDTH = 0,
    parameter AXI_WUSER_WIDTH = 0,
    parameter AXI_BUSER_WIDTH = 0,
    parameter AXI_ARUSER_WIDTH = 0,
    parameter AXI_RUSER_WIDTH = 0
)(
    input   wire                clk,
    input   wire                rst,
    input  wire                  ctrl_wen,
    input  wire [CTRL_ADDR_WIDTH-1:0] ctrl_waddr,
    input  wire [          31:0] ctrl_wdata,
    input  wire                  ctrl_ren,
    input  wire [CTRL_ADDR_WIDTH-1:0] ctrl_raddr,
    output reg  [          31:0] ctrl_rdata,
    
input   wire tk0_valid,
output  wire tk0_ready,
input   wire tk0_enable,
input   wire [6-1:0] tk0_data,
    

input   wire tk1_valid,
output  wire tk1_ready,
input   wire tk1_enable,
input   wire [34-1:0] tk1_data,
    

input   wire tk2_valid,
output  wire tk2_ready,
input   wire tk2_enable,
input   wire [26-1:0] tk2_data,
    
    /*
     * AXI master interface
     */
    output wire [AXI_ID_WIDTH-1:0]      m_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0]    m_axi_awaddr,
    output wire [7:0]                   m_axi_awlen,
    output wire [2:0]                   m_axi_awsize,
    output wire [1:0]                   m_axi_awburst,
    output wire                         m_axi_awlock,
    output wire [3:0]                   m_axi_awcache,
    output wire [2:0]                   m_axi_awprot,
    output wire [3:0]                   m_axi_awqos,
    output wire [3:0]                   m_axi_awregion,
    output wire [AXI_AWUSER_WIDTH-1:0]  m_axi_awuser,
    output wire                         m_axi_awvalid,
    input  wire                         m_axi_awready,
    output wire [AXI_DATA_WIDTH-1:0]    m_axi_wdata,
    output wire [AXI_STRB_WIDTH-1:0]    m_axi_wstrb,
    output wire                         m_axi_wlast,
    output wire [AXI_WUSER_WIDTH-1:0]   m_axi_wuser,
    output wire                         m_axi_wvalid,
    input  wire                         m_axi_wready,
    input  wire [AXI_ID_WIDTH-1:0]      m_axi_bid,
    input  wire [1:0]                   m_axi_bresp,
    input  wire [AXI_BUSER_WIDTH-1:0]   m_axi_buser,
    input  wire                         m_axi_bvalid,
    output wire                         m_axi_bready,
    output wire [AXI_ID_WIDTH-1:0]      m_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0]    m_axi_araddr,
    output wire [7:0]                   m_axi_arlen,
    output wire [2:0]                   m_axi_arsize,
    output wire [1:0]                   m_axi_arburst,
    output wire                         m_axi_arlock,
    output wire [3:0]                   m_axi_arcache,
    output wire [2:0]                   m_axi_arprot,
    output wire [3:0]                   m_axi_arqos,
    output wire [3:0]                   m_axi_arregion,
    output wire [AXI_ARUSER_WIDTH-1:0]  m_axi_aruser,
    output wire                         m_axi_arvalid,
    input  wire                         m_axi_arready,
    input  wire [AXI_ID_WIDTH-1:0]      m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]    m_axi_rdata,
    input  wire [1:0]                   m_axi_rresp,
    input  wire                         m_axi_rlast,
    input  wire [AXI_RUSER_WIDTH-1:0]   m_axi_ruser,
    input  wire                         m_axi_rvalid,
    output wire                         m_axi_rready
);
    wire                            tb_ovalid; 
    wire    [192-1:0]    tb_odata; 
    wire    [5-1:0]     tb_olen; 
    wire                            tb_oready;

    TraceBatch traceBatch (
        .clk(clk),
        .rst(rst),
        
.tk0_valid(tk0_valid),
.tk0_ready(tk0_ready),
.tk0_enable(tk0_enable),
.tk0_data(tk0_data),
    

.tk1_valid(tk1_valid),
.tk1_ready(tk1_ready),
.tk1_enable(tk1_enable),
.tk1_data(tk1_data),
    

.tk2_valid(tk2_valid),
.tk2_ready(tk2_ready),
.tk2_enable(tk2_enable),
.tk2_data(tk2_data),
    
        .ovalid(tb_ovalid), 
        .odata(tb_odata), 
        .olen(tb_olen),
        .oready(tb_oready)
    );

    wire fifo_ovalid;
    wire fifo_oready;
    wire [AXI_DATA_WIDTH-1:0] fifo_odata;

    FIFOTrans #(
        .IN_WIDTH(192),
        .OUT_WIDTH(AXI_DATA_WIDTH)
    ) fifoTrans (
        .clk(clk),
        .rst(rst),
        .ivalid(tb_ovalid),
        .iready(tb_oready),
        .idata(tb_odata),
        .ilen(tb_olen),
        .ovalid(fifo_ovalid),
        .oready(fifo_oready),
        .odata(fifo_odata)
    );

    FIFOAXI4Ctrl #(
        .CTRL_ADDR_WIDTH (CTRL_ADDR_WIDTH ),
        .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH  ),
        .AXI_DATA_WIDTH  (AXI_DATA_WIDTH  ),
        .AXI_STRB_WIDTH  (AXI_STRB_WIDTH  ),
        .AXI_ID_WIDTH    (AXI_ID_WIDTH    ),
        .AXI_BUSER_WIDTH (AXI_BUSER_WIDTH ),
        .AXI_WUSER_WIDTH (AXI_WUSER_WIDTH ),
        .AXI_AWUSER_WIDTH(AXI_AWUSER_WIDTH)
    ) ctrl (
        .clk(clk),
        .rst(rst),
        .ctrl_wen(ctrl_wen),
        .ctrl_waddr(ctrl_waddr),
        .ctrl_wdata(ctrl_wdata),
        .ctrl_ren(ctrl_ren),
        .ctrl_raddr(ctrl_raddr),
        .ctrl_rdata(ctrl_rdata),
        .ivalid(fifo_ovalid),
        .idata(fifo_odata),
        .iready(fifo_oready),
        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awlock(m_axi_awlock),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awqos(m_axi_awqos),
        .m_axi_awregion(m_axi_awregion),
        .m_axi_awuser(m_axi_awuser),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wuser(m_axi_wuser),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bid(m_axi_bid),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_buser(m_axi_buser),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready)
    );
    assign m_axi_arvalid = 0;
    assign m_axi_rready = 0;

endmodule

module TraceBatch (
    input   wire                clk,
    input   wire                rst,
    
input   wire tk0_valid,
output  wire tk0_ready,
input   wire tk0_enable,
input   wire [6-1:0] tk0_data,
    

input   wire tk1_valid,
output  wire tk1_ready,
input   wire tk1_enable,
input   wire [34-1:0] tk1_data,
    

input   wire tk2_valid,
output  wire tk2_ready,
input   wire tk2_enable,
input   wire [26-1:0] tk2_data,
    
    output  wire                            ovalid, 
    output  wire    [192-1:0]    odata, 
    output  wire    [5-1:0]     olen, 
    input   wire                            oready
);

    localparam AXI_DATA_WDITH = 64;
    localparam TRACE0_DATA_WIDTH = 6;
localparam TRACE1_DATA_WIDTH = 34;
localparam TRACE2_DATA_WIDTH = 26;
    wire [3-1:0] inputValids = {tk2_valid, tk1_valid, tk0_valid};
    wire [3-1:0] inputReadys = {tk2_ready, tk1_ready, tk0_ready};
    wire [3-1:0] inputFires  = inputValids & inputReadys;

    reg [5-1:0]     widthVec        [3:0];
    reg [3-1:0]         enableVec       [3:0];
    reg                         bufferValid;

    reg [15:0] pack0Vec [3:0];
reg [63:0] pack1Vec [3:0];
reg [103:0] pack2Vec [3:0];

    // ===========================================
    // ========= state assign logic ==============
    // ===========================================
    always @(posedge clk) begin
        if (!rst) begin
            bufferValid <= 0;
        end
        if (|inputFires) begin
            enableVec[0] <= {tk2_enable, tk1_enable, tk0_enable};
            pack0Vec[0] <= {2'd0, tk0_data, 8'd0};

pack1Vec[0] <= {6'd0, tk1_data, 8'd1, 16'd0};

pack2Vec[0] <= {6'd0, tk2_data, 8'd2, 48'd0, 16'd0};

            widthVec[0] <= 0;
            bufferValid <= tk0_enable|| tk1_enable|| tk2_enable;
        end
    end
    // ===========================================
    // ========== compress pipeline ==============
    // ===========================================
    wire    [3:0]     pipeValid; 
    wire    [3:0]     pipeReady;
    reg     [3-1:0]   hasData;
    assign pipeValid[0] = bufferValid;
    // assign tk0_ready = !bufferValid || pipeReady[0];
    // assign tk1_ready = !bufferValid || pipeReady[0];
    // assign tkn_ready = !bufferValid || pipeReady[0];
    assign tk0_ready = !bufferValid || pipeReady[0];
assign tk1_ready = !bufferValid || pipeReady[1];
assign tk2_ready = !bufferValid || pipeReady[2];
    generate
        for (genvar index = 0; index < 3; index ++) begin
            always @(posedge clk ) begin
                if (!rst) begin
                    hasData[index] <= 0;
                end
                else if (pipeValid[index] && pipeReady[index]) begin
                    hasData[index] <= 1;
                end
                else if (pipeValid[index+1] && pipeReady[index+1]) begin
                    hasData[index] <= 0;
                end
            end
            assign pipeReady[index] = !hasData[index] || pipeReady[index+1];
            assign pipeValid[index+1] = hasData[index];
        end
    endgenerate

    
    always @(posedge clk) begin
        if (pipeValid[0] && pipeReady[0]) begin
            enableVec[1] <= enableVec[0];
            if (enableVec[0][0]) begin
                pack0Vec[0] <= pack0Vec[1];
pack1Vec[0] <= pack1Vec[1];
pack2Vec[0] <= pack2Vec[1];
                widthVec[1] <= widthVec[0] + 5'd2;
            end
            else begin
                pack0Vec[0] <= 0;
pack1Vec[0] <= pack1Vec[1] >> 16;
pack2Vec[0] <= pack2Vec[1] >> 16;
                widthVec[1] <= widthVec[0];
            end
        end
    end
      

    always @(posedge clk) begin
        if (pipeValid[1] && pipeReady[1]) begin
            enableVec[2] <= enableVec[1];
            if (enableVec[1][1]) begin
                pack0Vec[1] <= pack0Vec[2];
pack1Vec[1] <= pack1Vec[2];
pack2Vec[1] <= pack2Vec[2];
                widthVec[2] <= widthVec[1] + 5'd6;
            end
            else begin
                pack0Vec[1] <= pack0Vec[2];
pack1Vec[1] <= 0;
pack2Vec[1] <= pack2Vec[2] >> 48;
                widthVec[2] <= widthVec[1];
            end
        end
    end
      

    always @(posedge clk) begin
        if (pipeValid[2] && pipeReady[2]) begin
            enableVec[3] <= enableVec[2];
            if (enableVec[2][2]) begin
                pack0Vec[2] <= pack0Vec[3];
pack1Vec[2] <= pack1Vec[3];
pack2Vec[2] <= pack2Vec[3];
                widthVec[3] <= widthVec[2] + 5'd5;
            end
            else begin
                pack0Vec[2] <= pack0Vec[3];
pack1Vec[2] <= pack1Vec[3];
pack2Vec[2] <= 0;
                widthVec[3] <= widthVec[2];
            end
        end
    end
      

    wire [64-1:0] endData = 'd0;
    assign pipeReady[3] = oready;
    assign ovalid = hasData[3-1];
    assign odata = { { 16'd0, endData, 8'd128 }, ({88'd0, pack0Vec[3]} | {40'd0, pack1Vec[3]} | pack2Vec[3]) };
    assign olen  = widthVec[3] + 5'd9;
endmodule

module FIFOAXI4Ctrl #(
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
  localparam REGADDR_WRITEMODE = 'd0;
  localparam REGADDR_BASEADDR_L = 'd4;
  localparam REGADDR_BASEADDR_H = 'd8;
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
    if (!rst) begin
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
    if (!rst) begin
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


module FIFOTrans #(
    parameter IN_WIDTH  = 104,
    parameter OUT_WIDTH = 64
) (
    input  wire                          clk,
    input  wire                          rst,
    input  wire                          ivalid,
    output wire                          iready,
    input  wire [          IN_WIDTH-1:0] idata,
    input  wire [$clog2(IN_WIDTH/8)-1:0] ilen,
    output wire                          ovalid,
    input  wire                          oready,
    output wire [         OUT_WIDTH-1:0] odata
);
  reg [IN_WIDTH-1:0] dataBuffer;
  reg [$clog2(IN_WIDTH/8)-1:0] lenBuffer;
  reg [$clog2(IN_WIDTH/8)-1:0] count;
  reg busy;
  always @(posedge clk) begin
    if (!rst) begin
      busy <= 'b0;
    end else if (ivalid && iready) begin
      busy <= 'b1;
      count <= 'd0;
      dataBuffer <= idata;
      lenBuffer <= ilen;
    end else if (ovalid && oready) begin
      if (count < lenBuffer) begin
        dataBuffer <= dataBuffer >> OUT_WIDTH;
        count <= count + (OUT_WIDTH/8);
      end else begin
        busy <= 'b0;
      end
    end
  end
  assign ovalid = busy;
  assign odata  = dataBuffer[OUT_WIDTH-1:0];
endmodule


