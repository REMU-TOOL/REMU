module emulib_rammodel_FIFOMAS #(
    parameter   ADDR_WIDTH      = 32,
    parameter   ID_WIDTH        = 4,
    parameter   MAX_R_INFLIGHT  = 8,
    parameter   MAX_W_INFLIGHT  = 8
)(

    input  wire                     clk,
    input  wire                     rst,

    input  wire                     arvalid,
    output wire                     arready,
    input  wire [ID_WIDTH-1:0]      arid,
    input  wire [ADDR_WIDTH-1:0]    araddr,
    input  wire [7:0]               arlen,
    input  wire [2:0]               arsize,
    input  wire [1:0]               arburst,

    input  wire                     awvalid,
    output wire                     awready,
    input  wire [ID_WIDTH-1:0]      awid,
    input  wire [ADDR_WIDTH-1:0]    awaddr,
    input  wire [7:0]               awlen,
    input  wire [2:0]               awsize,
    input  wire [1:0]               awburst,

    input  wire                     wvalid,
    output wire                     wready,
    input  wire                     wlast,

    output wire                     bvalid,
    input  wire                     bready,
    output wire [ID_WIDTH-1:0]      bid,

    output wire                     rvalid,
    input  wire                     rready,
    output wire [ID_WIDTH-1:0]      rid

);
parameter mm_relaxFunctionalModel =0,mm_openPagePolicy=1,mm_backendLatency =2,
          mm_dramTimings_tAL =0,mm_dramTimings_tCAS =14,mm_dramTimings_tCMD =1,
          mm_dramTimings_tCWD =10,mm_dramTimings_tCCD =4,mm_dramTimings_tFAW =25,
          mm_dramTimings_tRAS =33,mm_dramTimings_tREFI =7800,mm_dramTimings_tRC =47,
          mm_dramTimings_tRCD =14,mm_dramTimings_tRFC =160,mm_dramTimings_tRRD =8,
          mm_dramTimings_tRP =14,mm_dramTimings_tRTP =8,mm_dramTimings_tRTRS =2,
          mm_dramTimings_tWR =15,mm_dramTimings_tWTR =8,mm_rowAddr_offset =18,
          mm_rowAddr_mask =65535,mm_rankAddr_offset =16,mm_rankAddr_mask =3,
          mm_bankAddr_offset =13,mm_bankAddr_mask =7;
wire model_targetFire = 1'b1;

  wire [31:0] mm_totalReads;  
  wire [31:0] mm_totalWrites;  
  wire [31:0] mm_totalReadBeats;  
  wire [31:0] mm_totalWriteBeats;  
  wire [31:0] mm_readOutstandingHistogram_0;  
  wire [31:0] mm_readOutstandingHistogram_1;  
  wire [31:0] mm_readOutstandingHistogram_2;  
  wire [31:0] mm_readOutstandingHistogram_3;  
  wire [31:0] mm_writeOutstandingHistogram_0;  
  wire [31:0] mm_writeOutstandingHistogram_1;  
  wire [31:0] mm_writeOutstandingHistogram_2;  
  wire [31:0] mm_writeOutstandingHistogram_3;  
  wire [31:0] mm_rankPower_0_allPreCycles;  
  wire [31:0] mm_rankPower_0_numCASR;  
  wire [31:0] mm_rankPower_0_numCASW;  
  wire [31:0] mm_rankPower_0_numACT;  
  wire [31:0] mm_rankPower_1_allPreCycles;  
  wire [31:0] mm_rankPower_1_numCASR;  
  wire [31:0] mm_rankPower_1_numCASW;  
  wire [31:0] mm_rankPower_1_numACT;  
  wire [31:0] mm_rankPower_2_allPreCycles;  
  wire [31:0] mm_rankPower_2_numCASR;  
  wire [31:0] mm_rankPower_2_numCASW;  
  wire [31:0] mm_rankPower_2_numACT;  
  wire [31:0] mm_rankPower_3_allPreCycles;  
  wire [31:0] mm_rankPower_3_numCASR;  
  wire [31:0] mm_rankPower_3_numCASW;  
  wire [31:0] mm_rankPower_3_numACT;  
wire [7:0] w_len,r_len;

reg [7:0] rcnt;
    always @(posedge clk) begin
        if (rst) begin
            rcnt <= 0;
        end
        else if (rcnt == r_len) begin
            rcnt <= 0;
        end
        else if (rvalid && rready) begin
            rcnt <= rcnt + 1;
        end
    end
    
wire rlast = rcnt == r_len && rvalid && rready;

wire bq_iready,bq_ovalid;
wire rq_iready,rq_ovalid;
emulib_ready_valid_fifo #(
        .WIDTH      (ID_WIDTH+8),
        .DEPTH      (MAX_W_INFLIGHT),
        .FAST_READ  (1)
    ) bid_q (
        .clk        (clk),
        .rst        (rst),
        .ivalid     (awvalid && awready),
        .iready     (bq_iready),
        .idata      ({awid,awlen}),
        .ovalid     (bq_ovalid),
        .oready     (bready && bvalid),
        .odata      ({bid,w_len})
    );

emulib_ready_valid_fifo #(
        .WIDTH      (ID_WIDTH+8),
        .DEPTH      (MAX_R_INFLIGHT),
        .FAST_READ  (1)
    ) rid_q (
        .clk        (clk),
        .rst        (rst),
        .ivalid     (arvalid && arready),
        .iready     (rq_iready),
        .idata      ({arid,arlen}),
        .ovalid     (rq_ovalid),
        .oready     (rready && rvalid && rlast),
        .odata      ({rid,r_len})
    );
    
wire model_arvalid = arvalid && rq_iready;
wire model_awvalid = awvalid && bq_iready;
//avoid trigger timming model wrap assersion
wire [1:0] model_arburst = (arburst == 2'b10)? 2'b01 : arburst; 
wire [1:0] model_awburst = (awburst == 2'b10)? 2'b01 : awburst; 

emulib_fased_FIFOMASModel model (  
    .clock(clk),
    .reset(rst),
    .io_tNasti_aw_ready(awready),
    .io_tNasti_aw_valid(model_awvalid),
    .io_tNasti_aw_bits_addr({3'b0,awaddr}),
    .io_tNasti_aw_bits_len(awlen),
    .io_tNasti_aw_bits_burst(model_awburst),
    .io_tNasti_aw_bits_id(awid),
    .io_tNasti_w_ready(wready),
    .io_tNasti_w_valid(wvalid),
    .io_tNasti_w_bits_last(wlast),
    .io_tNasti_b_ready(bready),
    .io_tNasti_b_valid(bvalid),
    //.io_tNasti_b_bits_id(bid),
    .io_tNasti_ar_ready(arready),
    .io_tNasti_ar_valid(model_arvalid),
    .io_tNasti_ar_bits_addr({3'b0,araddr}),
    .io_tNasti_ar_bits_len(arlen),
    .io_tNasti_ar_bits_burst(model_arburst),
    .io_tNasti_ar_bits_id(arid),
    .io_tNasti_r_ready(rready),
    .io_tNasti_r_valid(rvalid),
    //.io_tNasti_r_bits_data(),
    //.io_tNasti_r_bits_last(),
    //.io_tNasti_r_bits_id(rid),
    // .io_egressReq_b_valid(model_io_egressReq_b_valid),
    //.io_egressReq_b_bits(model_io_egressReq_b_bits),
    // .io_egressReq_r_valid(model_io_egressReq_r_valid),
    // .io_egressReq_r_bits(model_io_egressReq_r_bits),
    .io_egressResp_bBits_id(bid),
    // .io_egressResp_bReady(model_io_egressResp_bReady),
    // .io_egressResp_rBits_data(model_io_egressResp_rBits_data),
    .io_egressResp_rBits_last(rlast),
    .io_egressResp_rBits_id(rid),
    // .io_egressResp_rReady(model_io_egressResp_rReady),
    .io_mmReg_totalReads(mm_totalReads),
    .io_mmReg_totalWrites(mm_totalWrites),
    .io_mmReg_totalReadBeats(mm_totalReadBeats),
    .io_mmReg_totalWriteBeats(mm_totalWriteBeats),
    .io_mmReg_readOutstandingHistogram_0(mm_readOutstandingHistogram_0),
    .io_mmReg_readOutstandingHistogram_1(mm_readOutstandingHistogram_1),
    .io_mmReg_readOutstandingHistogram_2(mm_readOutstandingHistogram_2),
    .io_mmReg_readOutstandingHistogram_3(mm_readOutstandingHistogram_3),
    .io_mmReg_writeOutstandingHistogram_0(mm_writeOutstandingHistogram_0),
    .io_mmReg_writeOutstandingHistogram_1(mm_writeOutstandingHistogram_1),
    .io_mmReg_writeOutstandingHistogram_2(mm_writeOutstandingHistogram_2),
    .io_mmReg_writeOutstandingHistogram_3(mm_writeOutstandingHistogram_3),
    .io_mmReg_bankAddr_offset(mm_bankAddr_offset),
    .io_mmReg_bankAddr_mask(mm_bankAddr_mask),
    .io_mmReg_rankAddr_offset(mm_rankAddr_offset),
    .io_mmReg_rankAddr_mask(mm_rankAddr_mask),
    .io_mmReg_rowAddr_offset(mm_rowAddr_offset),
    .io_mmReg_rowAddr_mask(mm_rowAddr_mask),
    .io_mmReg_openPagePolicy(mm_openPagePolicy),
    .io_mmReg_backendLatency(mm_backendLatency),
    .io_mmReg_dramTimings_tAL(mm_dramTimings_tAL),
    .io_mmReg_dramTimings_tCAS(mm_dramTimings_tCAS),
    .io_mmReg_dramTimings_tCMD(mm_dramTimings_tCMD),
    .io_mmReg_dramTimings_tCWD(mm_dramTimings_tCWD),
    .io_mmReg_dramTimings_tCCD(mm_dramTimings_tCCD),
    .io_mmReg_dramTimings_tFAW(mm_dramTimings_tFAW),
    .io_mmReg_dramTimings_tRAS(mm_dramTimings_tRAS),
    .io_mmReg_dramTimings_tREFI(mm_dramTimings_tREFI),
    .io_mmReg_dramTimings_tRC(mm_dramTimings_tRC),
    .io_mmReg_dramTimings_tRCD(mm_dramTimings_tRCD),
    .io_mmReg_dramTimings_tRFC(mm_dramTimings_tRFC),
    .io_mmReg_dramTimings_tRRD(mm_dramTimings_tRRD),
    .io_mmReg_dramTimings_tRP(mm_dramTimings_tRP),
    .io_mmReg_dramTimings_tRTP(mm_dramTimings_tRTP),
    .io_mmReg_dramTimings_tRTRS(mm_dramTimings_tRTRS),
    .io_mmReg_dramTimings_tWR(mm_dramTimings_tWR),
    .io_mmReg_dramTimings_tWTR(mm_dramTimings_tWTR),
    .io_mmReg_rankPower_0_allPreCycles(mm_rankPower_0_allPreCycles),
    .io_mmReg_rankPower_0_numCASR(mm_rankPower_0_numCASR),
    .io_mmReg_rankPower_0_numCASW(mm_rankPower_0_numCASW),
    .io_mmReg_rankPower_0_numACT(mm_rankPower_0_numACT),
    .io_mmReg_rankPower_1_allPreCycles(mm_rankPower_1_allPreCycles),
    .io_mmReg_rankPower_1_numCASR(mm_rankPower_1_numCASR),
    .io_mmReg_rankPower_1_numCASW(mm_rankPower_1_numCASW),
    .io_mmReg_rankPower_1_numACT(mm_rankPower_1_numACT),
    .io_mmReg_rankPower_2_allPreCycles(mm_rankPower_2_allPreCycles),
    .io_mmReg_rankPower_2_numCASR(mm_rankPower_2_numCASR),
    .io_mmReg_rankPower_2_numCASW(mm_rankPower_2_numCASW),
    .io_mmReg_rankPower_2_numACT(mm_rankPower_2_numACT),
    .io_mmReg_rankPower_3_allPreCycles(mm_rankPower_3_allPreCycles),
    .io_mmReg_rankPower_3_numCASR(mm_rankPower_3_numCASR),
    .io_mmReg_rankPower_3_numCASW(mm_rankPower_3_numCASW),
    .io_mmReg_rankPower_3_numACT(mm_rankPower_3_numACT),
    .targetFire(model_targetFire)
  );

    
endmodule

