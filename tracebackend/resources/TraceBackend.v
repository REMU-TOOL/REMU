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
    input   wire                host_clk,
    input   wire                host_rst,
    input   wire [63:0]         tick_cnt,
    input  wire                  ctrl_wen,
    input  wire [CTRL_ADDR_WIDTH-1:0] ctrl_waddr,
    input  wire [          31:0] ctrl_wdata,
    input  wire                  ctrl_ren,
    input  wire [CTRL_ADDR_WIDTH-1:0] ctrl_raddr,
    output wire [          31:0] ctrl_rdata,
    output wire                  trace_full,
    {tracePortDefine}
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
    wire    [{outDataWidth}-1:0]    tb_odata; 
    wire    [{outLenWidth}-1:0]     tb_olen; 
    wire                            tb_oready;

    TraceBatch traceBatch (
        .host_clk(host_clk),
        .host_rst(host_rst),
        .tick_cnt(tick_cnt),
        {tracePortInstance}
        .ovalid(tb_ovalid), 
        .odata(tb_odata), 
        .olen(tb_olen),
        .oready(tb_oready)
    );

    wire fifo_ovalid;
    wire fifo_oready;
    wire [AXI_DATA_WIDTH-1:0] fifo_odata;

    FIFOTrans #(
        .IN_WIDTH({outDataWidth}),
        .OUT_WIDTH(AXI_DATA_WIDTH)
    ) fifoTrans (
        .clk(host_clk),
        .rst(host_rst),
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
        .clk(host_clk),
        .rst(host_rst),
        .ctrl_wen(ctrl_wen),
        .ctrl_waddr(ctrl_waddr),
        .ctrl_wdata(ctrl_wdata),
        .ctrl_ren(ctrl_ren),
        .ctrl_raddr(ctrl_raddr),
        .ctrl_rdata(ctrl_rdata),
        .trace_full(trace_full),
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