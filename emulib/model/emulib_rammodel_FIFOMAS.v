module emulib_rammodel_FIFOMAS #(
    parameter   ADDR_WIDTH      = 32,
    parameter   ID_WIDTH        = 4
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
assign rid = 0;
assign bid = 0;
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
reg [7:0] beats;
always @(posedge clk ) begin
	if(rst)
		beats <= 0;
	else if(arvalid && arready)
		beats <= arlen;
	else if(rlast)
		beats <=0;
end
reg [7:0] rcnt;
    always @(posedge clk) begin
        if (rst) begin
            rcnt <= 0;
        end
        else if (rcnt == beats) begin
            rcnt <= 0;
        end
        else if (rvalid && rready) begin
            rcnt <= rcnt + 1;
        end
    end

wire rlast = rcnt == beats && rvalid && rready;

FIFOMASModel model (  
    .clock(clk),
    .reset(rst),
    .io_tNasti_aw_ready(awready),
    .io_tNasti_aw_valid(awvalid),
    .io_tNasti_aw_bits_addr({3'b0,awaddr}),
    .io_tNasti_aw_bits_len(awlen),
    .io_tNasti_aw_bits_burst(awburst),
    .io_tNasti_aw_bits_id(awid),
    .io_tNasti_w_ready(wready),
    .io_tNasti_w_valid(wvalid),
    .io_tNasti_w_bits_last(wlast),
    .io_tNasti_b_ready(bready),
    .io_tNasti_b_valid(bvalid),
    //.io_tNasti_b_bits_id(bid),
    .io_tNasti_ar_ready(arready),
    .io_tNasti_ar_valid(arvalid),
    .io_tNasti_ar_bits_addr({3'b0,araddr}),
    .io_tNasti_ar_bits_len(arlen),
    .io_tNasti_ar_bits_burst(arburst),
    .io_tNasti_ar_bits_id(arid),
    .io_tNasti_r_ready(rready),
    .io_tNasti_r_valid(rvalid),
    //.io_tNasti_r_bits_data(),
    //.io_tNasti_r_bits_last(),
    //.io_tNasti_r_bits_id(rid),
    // .io_egressReq_b_valid(model_io_egressReq_b_valid),
    // .io_egressReq_b_bits(model_io_egressReq_b_bits),
    // .io_egressReq_r_valid(model_io_egressReq_r_valid),
    // .io_egressReq_r_bits(model_io_egressReq_r_bits),
    // .io_egressResp_bBits_id(model_io_egressResp_bBits_id),
    // .io_egressResp_bReady(model_io_egressResp_bReady),
    // .io_egressResp_rBits_data(model_io_egressResp_rBits_data),
    .io_egressResp_rBits_last(rlast),
    // .io_egressResp_rBits_id(model_io_egressResp_rBits_id),
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


module FIFOMASModel(
  input         clock,
  input         reset,
  output        io_tNasti_aw_ready,
  input         io_tNasti_aw_valid,
  input  [34:0] io_tNasti_aw_bits_addr,
  input  [7:0]  io_tNasti_aw_bits_len,
  input  [1:0]  io_tNasti_aw_bits_burst,
  input  [3:0]  io_tNasti_aw_bits_id,
  output        io_tNasti_w_ready,
  input         io_tNasti_w_valid,
  input         io_tNasti_w_bits_last,
  input         io_tNasti_b_ready,
  output        io_tNasti_b_valid,
  output [3:0]  io_tNasti_b_bits_id,
  output        io_tNasti_ar_ready,
  input         io_tNasti_ar_valid,
  input  [34:0] io_tNasti_ar_bits_addr,
  input  [7:0]  io_tNasti_ar_bits_len,
  input  [1:0]  io_tNasti_ar_bits_burst,
  input  [3:0]  io_tNasti_ar_bits_id,
  input         io_tNasti_r_ready,
  output        io_tNasti_r_valid,
  output [63:0] io_tNasti_r_bits_data,
  output        io_tNasti_r_bits_last,
  output [3:0]  io_tNasti_r_bits_id,
  output        io_egressReq_b_valid,
  output [3:0]  io_egressReq_b_bits,
  output        io_egressReq_r_valid,
  output [3:0]  io_egressReq_r_bits,
  input  [3:0]  io_egressResp_bBits_id,
  output        io_egressResp_bReady,
  input  [63:0] io_egressResp_rBits_data,
  input         io_egressResp_rBits_last,
  input  [3:0]  io_egressResp_rBits_id,
  output        io_egressResp_rReady,
  output [31:0] io_mmReg_totalReads,
  output [31:0] io_mmReg_totalWrites,
  output [31:0] io_mmReg_totalReadBeats,
  output [31:0] io_mmReg_totalWriteBeats,
  output [31:0] io_mmReg_readOutstandingHistogram_0,
  output [31:0] io_mmReg_readOutstandingHistogram_1,
  output [31:0] io_mmReg_readOutstandingHistogram_2,
  output [31:0] io_mmReg_readOutstandingHistogram_3,
  output [31:0] io_mmReg_writeOutstandingHistogram_0,
  output [31:0] io_mmReg_writeOutstandingHistogram_1,
  output [31:0] io_mmReg_writeOutstandingHistogram_2,
  output [31:0] io_mmReg_writeOutstandingHistogram_3,
  input  [31:0] io_mmReg_bankAddr_offset,
  input  [2:0]  io_mmReg_bankAddr_mask,
  input  [31:0] io_mmReg_rankAddr_offset,
  input  [1:0]  io_mmReg_rankAddr_mask,
  input  [31:0] io_mmReg_rowAddr_offset,
  input  [25:0] io_mmReg_rowAddr_mask,
  input         io_mmReg_openPagePolicy,
  input  [11:0] io_mmReg_backendLatency,
  input  [6:0]  io_mmReg_dramTimings_tAL,
  input  [6:0]  io_mmReg_dramTimings_tCAS,
   input  [6:0]  io_mmReg_dramTimings_tCMD,
   input  [6:0]  io_mmReg_dramTimings_tCWD,
   input  [6:0]  io_mmReg_dramTimings_tCCD,
   input  [6:0]  io_mmReg_dramTimings_tFAW,
   input  [6:0]  io_mmReg_dramTimings_tRAS,
   input  [13:0] io_mmReg_dramTimings_tREFI,
   input  [6:0]  io_mmReg_dramTimings_tRC,
   input  [6:0]  io_mmReg_dramTimings_tRCD,
   input  [9:0]  io_mmReg_dramTimings_tRFC,
   input  [6:0]  io_mmReg_dramTimings_tRRD,
   input  [6:0]  io_mmReg_dramTimings_tRP,
   input  [6:0]  io_mmReg_dramTimings_tRTP,
   input  [6:0]  io_mmReg_dramTimings_tRTRS,
   input  [6:0]  io_mmReg_dramTimings_tWR,
   input  [6:0]  io_mmReg_dramTimings_tWTR,
   output [31:0] io_mmReg_rankPower_0_allPreCycles,
   output [31:0] io_mmReg_rankPower_0_numCASR,
   output [31:0] io_mmReg_rankPower_0_numCASW,
   output [31:0] io_mmReg_rankPower_0_numACT,
   output [31:0] io_mmReg_rankPower_1_allPreCycles,
   output [31:0] io_mmReg_rankPower_1_numCASR,
   output [31:0] io_mmReg_rankPower_1_numCASW,
   output [31:0] io_mmReg_rankPower_1_numACT,
   output [31:0] io_mmReg_rankPower_2_allPreCycles,
   output [31:0] io_mmReg_rankPower_2_numCASR,
   output [31:0] io_mmReg_rankPower_2_numCASW,
   output [31:0] io_mmReg_rankPower_2_numACT,
   output [31:0] io_mmReg_rankPower_3_allPreCycles,
   output [31:0] io_mmReg_rankPower_3_numCASR,
   output [31:0] io_mmReg_rankPower_3_numCASW,
   output [31:0] io_mmReg_rankPower_3_numACT,
  input         targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [63:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
  reg [31:0] _RAND_3;
  reg [31:0] _RAND_4;
  reg [31:0] _RAND_5;
  reg [31:0] _RAND_6;
  reg [31:0] _RAND_7;
  reg [31:0] _RAND_8;
  reg [31:0] _RAND_9;
  reg [31:0] _RAND_10;
  reg [31:0] _RAND_11;
  reg [31:0] _RAND_12;
`endif // RANDOMIZE_REG_INIT
  wire  nastiReqIden_io_in_aw_ready;
  wire  nastiReqIden_io_in_aw_valid;
  wire [34:0] nastiReqIden_io_in_aw_bits_addr;
  wire [3:0] nastiReqIden_io_in_aw_bits_id;
  wire  nastiReqIden_io_in_w_ready;
  wire  nastiReqIden_io_in_w_valid;
  wire  nastiReqIden_io_in_w_bits_last;
  wire  nastiReqIden_io_in_ar_ready;
  wire  nastiReqIden_io_in_ar_valid;
  wire [34:0] nastiReqIden_io_in_ar_bits_addr;
  wire [3:0] nastiReqIden_io_in_ar_bits_id;
  wire  nastiReqIden_io_out_aw_ready;
  wire  nastiReqIden_io_out_aw_valid;
  wire [34:0] nastiReqIden_io_out_aw_bits_addr;
  wire [3:0] nastiReqIden_io_out_aw_bits_id;
  wire  nastiReqIden_io_out_w_ready;
  wire  nastiReqIden_io_out_w_valid;
  wire  nastiReqIden_io_out_w_bits_last;
  wire  nastiReqIden_io_out_ar_ready;
  wire  nastiReqIden_io_out_ar_valid;
  wire [34:0] nastiReqIden_io_out_ar_bits_addr;
  wire [3:0] nastiReqIden_io_out_ar_bits_id;
  wire  monitor_clock;
  wire  monitor_reset;
  wire  monitor_axi4_aw_ready;
  wire  monitor_axi4_aw_valid;
  wire [7:0] monitor_axi4_aw_bits_len;
  wire  monitor_axi4_ar_ready;
  wire  monitor_axi4_ar_valid;
  wire [7:0] monitor_axi4_ar_bits_len;
  wire  monitor_targetFire;
  wire  SatUpDownCounter_clock;
  wire  SatUpDownCounter_reset;
  wire  SatUpDownCounter_io_inc;
  wire  SatUpDownCounter_io_dec;
  wire [3:0] SatUpDownCounter_io_value;
  wire  SatUpDownCounter_io_full;
  wire  SatUpDownCounter_io_empty;
  wire  SatUpDownCounter_targetFire;
  wire  SatUpDownCounter_1_clock;
  wire  SatUpDownCounter_1_reset;
  wire  SatUpDownCounter_1_io_inc;
  wire  SatUpDownCounter_1_io_dec;
  wire [3:0] SatUpDownCounter_1_io_value;
  wire  SatUpDownCounter_1_io_full;
  wire  SatUpDownCounter_1_io_empty;
  wire  SatUpDownCounter_1_targetFire;
  wire  SatUpDownCounter_2_clock;
  wire  SatUpDownCounter_2_reset;
  wire  SatUpDownCounter_2_io_inc;
  wire  SatUpDownCounter_2_io_dec;
  wire [3:0] SatUpDownCounter_2_io_value;
  wire  SatUpDownCounter_2_io_full;
  wire  SatUpDownCounter_2_io_empty;
  wire  SatUpDownCounter_2_targetFire;
  wire  xactionRelease_clock;
  wire  xactionRelease_reset;
  wire  xactionRelease_io_b_ready;
  wire  xactionRelease_io_b_valid;
  wire [3:0] xactionRelease_io_b_bits_id;
  wire  xactionRelease_io_r_ready;
  wire  xactionRelease_io_r_valid;
  wire [63:0] xactionRelease_io_r_bits_data;
  wire  xactionRelease_io_r_bits_last;
  wire [3:0] xactionRelease_io_r_bits_id;
  wire  xactionRelease_io_egressReq_b_valid;
  wire [3:0] xactionRelease_io_egressReq_b_bits;
  wire  xactionRelease_io_egressReq_r_valid;
  wire [3:0] xactionRelease_io_egressReq_r_bits;
  wire [3:0] xactionRelease_io_egressResp_bBits_id;
  wire  xactionRelease_io_egressResp_bReady;
  wire [63:0] xactionRelease_io_egressResp_rBits_data;
  wire  xactionRelease_io_egressResp_rBits_last;
  wire [3:0] xactionRelease_io_egressResp_rBits_id;
  wire  xactionRelease_io_egressResp_rReady;
  wire  xactionRelease_io_nextRead_ready;
  wire  xactionRelease_io_nextRead_valid;
  wire [3:0] xactionRelease_io_nextRead_bits_id;
  wire  xactionRelease_io_nextWrite_ready;
  wire  xactionRelease_io_nextWrite_valid;
  wire [3:0] xactionRelease_io_nextWrite_bits_id;
  wire  xactionRelease_targetFire;
  wire  backend_clock;
  wire  backend_reset;
  wire  backend_io_newRead_ready;
  wire  backend_io_newRead_valid;
  wire [3:0] backend_io_newRead_bits_id;
  wire  backend_io_newWrite_ready;
  wire  backend_io_newWrite_valid;
  wire [3:0] backend_io_newWrite_bits_id;
  wire  backend_io_completedRead_ready;
  wire  backend_io_completedRead_valid;
  wire [3:0] backend_io_completedRead_bits_id;
  wire  backend_io_completedWrite_ready;
  wire  backend_io_completedWrite_valid;
  wire [3:0] backend_io_completedWrite_bits_id;
  wire [11:0] backend_io_readLatency;
  wire [11:0] backend_io_tCycle;
  wire  backend_targetFire;
  wire  xactionScheduler_clock;
  wire  xactionScheduler_reset;
  wire  xactionScheduler_io_req_aw_ready;
  wire  xactionScheduler_io_req_aw_valid;
  wire [34:0] xactionScheduler_io_req_aw_bits_addr;
  wire [3:0] xactionScheduler_io_req_aw_bits_id;
  wire  xactionScheduler_io_req_w_ready;
  wire  xactionScheduler_io_req_w_valid;
  wire  xactionScheduler_io_req_w_bits_last;
  wire  xactionScheduler_io_req_ar_ready;
  wire  xactionScheduler_io_req_ar_valid;
  wire [34:0] xactionScheduler_io_req_ar_bits_addr;
  wire [3:0] xactionScheduler_io_req_ar_bits_id;
  wire  xactionScheduler_io_nextXaction_ready;
  wire  xactionScheduler_io_nextXaction_valid;
  wire [3:0] xactionScheduler_io_nextXaction_bits_xaction_id;
  wire  xactionScheduler_io_nextXaction_bits_xaction_isWrite;
  wire [34:0] xactionScheduler_io_nextXaction_bits_addr;
  wire [10:0] xactionScheduler_io_pendingWReq;
  wire [10:0] xactionScheduler_io_pendingAWReq;
  wire  xactionScheduler_targetFire;
  wire  currentReference_clock;
  wire  currentReference_reset;
  wire  currentReference_io_enq_ready;
  wire  currentReference_io_enq_valid;
  wire [3:0] currentReference_io_enq_bits_xaction_id;
  wire  currentReference_io_enq_bits_xaction_isWrite;
  wire [25:0] currentReference_io_enq_bits_rowAddr;
  wire [2:0] currentReference_io_enq_bits_bankAddr;
  wire [1:0] currentReference_io_enq_bits_rankAddr;
  wire  currentReference_io_deq_ready;
  wire  currentReference_io_deq_valid;
  wire [3:0] currentReference_io_deq_bits_xaction_id;
  wire  currentReference_io_deq_bits_xaction_isWrite;
  wire [25:0] currentReference_io_deq_bits_rowAddr;
  wire [2:0] currentReference_io_deq_bits_bankAddr;
  wire [1:0] currentReference_io_deq_bits_rankAddr;
  wire  currentReference_targetFire;
  wire  cmdBusBusy_clock;
  wire  cmdBusBusy_reset;
  wire  cmdBusBusy_io_set_valid;
  wire [6:0] cmdBusBusy_io_set_bits;
  wire  cmdBusBusy_io_idle;
  wire  cmdBusBusy_targetFire;
  wire  rankStateTrackers_0_clock;
  wire  rankStateTrackers_0_reset;
  wire [6:0] rankStateTrackers_0_io_timings_tAL;
  wire [6:0] rankStateTrackers_0_io_timings_tCAS;
  wire [6:0] rankStateTrackers_0_io_timings_tCWD;
  wire [6:0] rankStateTrackers_0_io_timings_tCCD;
  wire [6:0] rankStateTrackers_0_io_timings_tFAW;
  wire [6:0] rankStateTrackers_0_io_timings_tRAS;
  wire [13:0] rankStateTrackers_0_io_timings_tREFI;
  wire [6:0] rankStateTrackers_0_io_timings_tRC;
  wire [6:0] rankStateTrackers_0_io_timings_tRCD;
  wire [9:0] rankStateTrackers_0_io_timings_tRFC;
  wire [6:0] rankStateTrackers_0_io_timings_tRRD;
  wire [6:0] rankStateTrackers_0_io_timings_tRP;
  wire [6:0] rankStateTrackers_0_io_timings_tRTP;
  wire [6:0] rankStateTrackers_0_io_timings_tRTRS;
  wire [6:0] rankStateTrackers_0_io_timings_tWR;
  wire [6:0] rankStateTrackers_0_io_timings_tWTR;
  wire [2:0] rankStateTrackers_0_io_selectedCmd;
  wire  rankStateTrackers_0_io_autoPRE;
  wire [25:0] rankStateTrackers_0_io_cmdRow;
  wire  rankStateTrackers_0_io_rank_canCASW;
  wire  rankStateTrackers_0_io_rank_canCASR;
  wire  rankStateTrackers_0_io_rank_canPRE;
  wire  rankStateTrackers_0_io_rank_canACT;
  wire  rankStateTrackers_0_io_rank_canREF;
  wire  rankStateTrackers_0_io_rank_wantREF;
  wire  rankStateTrackers_0_io_rank_state;
  wire  rankStateTrackers_0_io_rank_banks_0_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_0_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_0_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_0_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_0_openRow;
  wire  rankStateTrackers_0_io_rank_banks_0_state;
  wire  rankStateTrackers_0_io_rank_banks_1_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_1_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_1_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_1_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_1_openRow;
  wire  rankStateTrackers_0_io_rank_banks_1_state;
  wire  rankStateTrackers_0_io_rank_banks_2_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_2_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_2_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_2_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_2_openRow;
  wire  rankStateTrackers_0_io_rank_banks_2_state;
  wire  rankStateTrackers_0_io_rank_banks_3_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_3_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_3_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_3_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_3_openRow;
  wire  rankStateTrackers_0_io_rank_banks_3_state;
  wire  rankStateTrackers_0_io_rank_banks_4_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_4_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_4_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_4_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_4_openRow;
  wire  rankStateTrackers_0_io_rank_banks_4_state;
  wire  rankStateTrackers_0_io_rank_banks_5_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_5_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_5_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_5_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_5_openRow;
  wire  rankStateTrackers_0_io_rank_banks_5_state;
  wire  rankStateTrackers_0_io_rank_banks_6_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_6_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_6_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_6_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_6_openRow;
  wire  rankStateTrackers_0_io_rank_banks_6_state;
  wire  rankStateTrackers_0_io_rank_banks_7_canCASW;
  wire  rankStateTrackers_0_io_rank_banks_7_canCASR;
  wire  rankStateTrackers_0_io_rank_banks_7_canPRE;
  wire  rankStateTrackers_0_io_rank_banks_7_canACT;
  wire [25:0] rankStateTrackers_0_io_rank_banks_7_openRow;
  wire  rankStateTrackers_0_io_rank_banks_7_state;
  wire [6:0] rankStateTrackers_0_io_tCycle;
  wire  rankStateTrackers_0_io_cmdUsesThisRank;
  wire [7:0] rankStateTrackers_0_io_cmdBankOH;
  wire  rankStateTrackers_0_targetFire;
  wire  rankStateTrackers_1_clock;
  wire  rankStateTrackers_1_reset;
  wire [6:0] rankStateTrackers_1_io_timings_tAL;
  wire [6:0] rankStateTrackers_1_io_timings_tCAS;
  wire [6:0] rankStateTrackers_1_io_timings_tCWD;
  wire [6:0] rankStateTrackers_1_io_timings_tCCD;
  wire [6:0] rankStateTrackers_1_io_timings_tFAW;
  wire [6:0] rankStateTrackers_1_io_timings_tRAS;
  wire [13:0] rankStateTrackers_1_io_timings_tREFI;
  wire [6:0] rankStateTrackers_1_io_timings_tRC;
  wire [6:0] rankStateTrackers_1_io_timings_tRCD;
  wire [9:0] rankStateTrackers_1_io_timings_tRFC;
  wire [6:0] rankStateTrackers_1_io_timings_tRRD;
  wire [6:0] rankStateTrackers_1_io_timings_tRP;
  wire [6:0] rankStateTrackers_1_io_timings_tRTP;
  wire [6:0] rankStateTrackers_1_io_timings_tRTRS;
  wire [6:0] rankStateTrackers_1_io_timings_tWR;
  wire [6:0] rankStateTrackers_1_io_timings_tWTR;
  wire [2:0] rankStateTrackers_1_io_selectedCmd;
  wire  rankStateTrackers_1_io_autoPRE;
  wire [25:0] rankStateTrackers_1_io_cmdRow;
  wire  rankStateTrackers_1_io_rank_canCASW;
  wire  rankStateTrackers_1_io_rank_canCASR;
  wire  rankStateTrackers_1_io_rank_canPRE;
  wire  rankStateTrackers_1_io_rank_canACT;
  wire  rankStateTrackers_1_io_rank_canREF;
  wire  rankStateTrackers_1_io_rank_wantREF;
  wire  rankStateTrackers_1_io_rank_state;
  wire  rankStateTrackers_1_io_rank_banks_0_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_0_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_0_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_0_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_0_openRow;
  wire  rankStateTrackers_1_io_rank_banks_0_state;
  wire  rankStateTrackers_1_io_rank_banks_1_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_1_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_1_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_1_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_1_openRow;
  wire  rankStateTrackers_1_io_rank_banks_1_state;
  wire  rankStateTrackers_1_io_rank_banks_2_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_2_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_2_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_2_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_2_openRow;
  wire  rankStateTrackers_1_io_rank_banks_2_state;
  wire  rankStateTrackers_1_io_rank_banks_3_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_3_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_3_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_3_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_3_openRow;
  wire  rankStateTrackers_1_io_rank_banks_3_state;
  wire  rankStateTrackers_1_io_rank_banks_4_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_4_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_4_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_4_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_4_openRow;
  wire  rankStateTrackers_1_io_rank_banks_4_state;
  wire  rankStateTrackers_1_io_rank_banks_5_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_5_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_5_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_5_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_5_openRow;
  wire  rankStateTrackers_1_io_rank_banks_5_state;
  wire  rankStateTrackers_1_io_rank_banks_6_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_6_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_6_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_6_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_6_openRow;
  wire  rankStateTrackers_1_io_rank_banks_6_state;
  wire  rankStateTrackers_1_io_rank_banks_7_canCASW;
  wire  rankStateTrackers_1_io_rank_banks_7_canCASR;
  wire  rankStateTrackers_1_io_rank_banks_7_canPRE;
  wire  rankStateTrackers_1_io_rank_banks_7_canACT;
  wire [25:0] rankStateTrackers_1_io_rank_banks_7_openRow;
  wire  rankStateTrackers_1_io_rank_banks_7_state;
  wire [6:0] rankStateTrackers_1_io_tCycle;
  wire  rankStateTrackers_1_io_cmdUsesThisRank;
  wire [7:0] rankStateTrackers_1_io_cmdBankOH;
  wire  rankStateTrackers_1_targetFire;
  wire  rankStateTrackers_2_clock;
  wire  rankStateTrackers_2_reset;
  wire [6:0] rankStateTrackers_2_io_timings_tAL;
  wire [6:0] rankStateTrackers_2_io_timings_tCAS;
  wire [6:0] rankStateTrackers_2_io_timings_tCWD;
  wire [6:0] rankStateTrackers_2_io_timings_tCCD;
  wire [6:0] rankStateTrackers_2_io_timings_tFAW;
  wire [6:0] rankStateTrackers_2_io_timings_tRAS;
  wire [13:0] rankStateTrackers_2_io_timings_tREFI;
  wire [6:0] rankStateTrackers_2_io_timings_tRC;
  wire [6:0] rankStateTrackers_2_io_timings_tRCD;
  wire [9:0] rankStateTrackers_2_io_timings_tRFC;
  wire [6:0] rankStateTrackers_2_io_timings_tRRD;
  wire [6:0] rankStateTrackers_2_io_timings_tRP;
  wire [6:0] rankStateTrackers_2_io_timings_tRTP;
  wire [6:0] rankStateTrackers_2_io_timings_tRTRS;
  wire [6:0] rankStateTrackers_2_io_timings_tWR;
  wire [6:0] rankStateTrackers_2_io_timings_tWTR;
  wire [2:0] rankStateTrackers_2_io_selectedCmd;
  wire  rankStateTrackers_2_io_autoPRE;
  wire [25:0] rankStateTrackers_2_io_cmdRow;
  wire  rankStateTrackers_2_io_rank_canCASW;
  wire  rankStateTrackers_2_io_rank_canCASR;
  wire  rankStateTrackers_2_io_rank_canPRE;
  wire  rankStateTrackers_2_io_rank_canACT;
  wire  rankStateTrackers_2_io_rank_canREF;
  wire  rankStateTrackers_2_io_rank_wantREF;
  wire  rankStateTrackers_2_io_rank_state;
  wire  rankStateTrackers_2_io_rank_banks_0_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_0_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_0_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_0_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_0_openRow;
  wire  rankStateTrackers_2_io_rank_banks_0_state;
  wire  rankStateTrackers_2_io_rank_banks_1_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_1_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_1_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_1_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_1_openRow;
  wire  rankStateTrackers_2_io_rank_banks_1_state;
  wire  rankStateTrackers_2_io_rank_banks_2_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_2_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_2_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_2_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_2_openRow;
  wire  rankStateTrackers_2_io_rank_banks_2_state;
  wire  rankStateTrackers_2_io_rank_banks_3_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_3_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_3_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_3_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_3_openRow;
  wire  rankStateTrackers_2_io_rank_banks_3_state;
  wire  rankStateTrackers_2_io_rank_banks_4_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_4_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_4_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_4_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_4_openRow;
  wire  rankStateTrackers_2_io_rank_banks_4_state;
  wire  rankStateTrackers_2_io_rank_banks_5_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_5_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_5_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_5_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_5_openRow;
  wire  rankStateTrackers_2_io_rank_banks_5_state;
  wire  rankStateTrackers_2_io_rank_banks_6_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_6_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_6_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_6_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_6_openRow;
  wire  rankStateTrackers_2_io_rank_banks_6_state;
  wire  rankStateTrackers_2_io_rank_banks_7_canCASW;
  wire  rankStateTrackers_2_io_rank_banks_7_canCASR;
  wire  rankStateTrackers_2_io_rank_banks_7_canPRE;
  wire  rankStateTrackers_2_io_rank_banks_7_canACT;
  wire [25:0] rankStateTrackers_2_io_rank_banks_7_openRow;
  wire  rankStateTrackers_2_io_rank_banks_7_state;
  wire [6:0] rankStateTrackers_2_io_tCycle;
  wire  rankStateTrackers_2_io_cmdUsesThisRank;
  wire [7:0] rankStateTrackers_2_io_cmdBankOH;
  wire  rankStateTrackers_2_targetFire;
  wire  rankStateTrackers_3_clock;
  wire  rankStateTrackers_3_reset;
  wire [6:0] rankStateTrackers_3_io_timings_tAL;
  wire [6:0] rankStateTrackers_3_io_timings_tCAS;
  wire [6:0] rankStateTrackers_3_io_timings_tCWD;
  wire [6:0] rankStateTrackers_3_io_timings_tCCD;
  wire [6:0] rankStateTrackers_3_io_timings_tFAW;
  wire [6:0] rankStateTrackers_3_io_timings_tRAS;
  wire [13:0] rankStateTrackers_3_io_timings_tREFI;
  wire [6:0] rankStateTrackers_3_io_timings_tRC;
  wire [6:0] rankStateTrackers_3_io_timings_tRCD;
  wire [9:0] rankStateTrackers_3_io_timings_tRFC;
  wire [6:0] rankStateTrackers_3_io_timings_tRRD;
  wire [6:0] rankStateTrackers_3_io_timings_tRP;
  wire [6:0] rankStateTrackers_3_io_timings_tRTP;
  wire [6:0] rankStateTrackers_3_io_timings_tRTRS;
  wire [6:0] rankStateTrackers_3_io_timings_tWR;
  wire [6:0] rankStateTrackers_3_io_timings_tWTR;
  wire [2:0] rankStateTrackers_3_io_selectedCmd;
  wire  rankStateTrackers_3_io_autoPRE;
  wire [25:0] rankStateTrackers_3_io_cmdRow;
  wire  rankStateTrackers_3_io_rank_canCASW;
  wire  rankStateTrackers_3_io_rank_canCASR;
  wire  rankStateTrackers_3_io_rank_canPRE;
  wire  rankStateTrackers_3_io_rank_canACT;
  wire  rankStateTrackers_3_io_rank_canREF;
  wire  rankStateTrackers_3_io_rank_wantREF;
  wire  rankStateTrackers_3_io_rank_state;
  wire  rankStateTrackers_3_io_rank_banks_0_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_0_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_0_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_0_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_0_openRow;
  wire  rankStateTrackers_3_io_rank_banks_0_state;
  wire  rankStateTrackers_3_io_rank_banks_1_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_1_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_1_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_1_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_1_openRow;
  wire  rankStateTrackers_3_io_rank_banks_1_state;
  wire  rankStateTrackers_3_io_rank_banks_2_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_2_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_2_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_2_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_2_openRow;
  wire  rankStateTrackers_3_io_rank_banks_2_state;
  wire  rankStateTrackers_3_io_rank_banks_3_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_3_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_3_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_3_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_3_openRow;
  wire  rankStateTrackers_3_io_rank_banks_3_state;
  wire  rankStateTrackers_3_io_rank_banks_4_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_4_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_4_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_4_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_4_openRow;
  wire  rankStateTrackers_3_io_rank_banks_4_state;
  wire  rankStateTrackers_3_io_rank_banks_5_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_5_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_5_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_5_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_5_openRow;
  wire  rankStateTrackers_3_io_rank_banks_5_state;
  wire  rankStateTrackers_3_io_rank_banks_6_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_6_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_6_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_6_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_6_openRow;
  wire  rankStateTrackers_3_io_rank_banks_6_state;
  wire  rankStateTrackers_3_io_rank_banks_7_canCASW;
  wire  rankStateTrackers_3_io_rank_banks_7_canCASR;
  wire  rankStateTrackers_3_io_rank_banks_7_canPRE;
  wire  rankStateTrackers_3_io_rank_banks_7_canACT;
  wire [25:0] rankStateTrackers_3_io_rank_banks_7_openRow;
  wire  rankStateTrackers_3_io_rank_banks_7_state;
  wire [6:0] rankStateTrackers_3_io_tCycle;
  wire  rankStateTrackers_3_io_cmdUsesThisRank;
  wire [7:0] rankStateTrackers_3_io_cmdBankOH;
  wire  rankStateTrackers_3_targetFire;
  wire  RefreshUnit_io_rankStati_0_canPRE;
  wire  RefreshUnit_io_rankStati_0_canREF;
  wire  RefreshUnit_io_rankStati_0_wantREF;
  wire  RefreshUnit_io_rankStati_0_banks_0_canPRE;
  wire  RefreshUnit_io_rankStati_0_banks_1_canPRE;
  wire  RefreshUnit_io_rankStati_0_banks_2_canPRE;
  wire  RefreshUnit_io_rankStati_0_banks_3_canPRE;
  wire  RefreshUnit_io_rankStati_0_banks_4_canPRE;
  wire  RefreshUnit_io_rankStati_0_banks_5_canPRE;
  wire  RefreshUnit_io_rankStati_0_banks_6_canPRE;
  wire  RefreshUnit_io_rankStati_0_banks_7_canPRE;
  wire  RefreshUnit_io_rankStati_1_canPRE;
  wire  RefreshUnit_io_rankStati_1_canREF;
  wire  RefreshUnit_io_rankStati_1_wantREF;
  wire  RefreshUnit_io_rankStati_1_banks_0_canPRE;
  wire  RefreshUnit_io_rankStati_1_banks_1_canPRE;
  wire  RefreshUnit_io_rankStati_1_banks_2_canPRE;
  wire  RefreshUnit_io_rankStati_1_banks_3_canPRE;
  wire  RefreshUnit_io_rankStati_1_banks_4_canPRE;
  wire  RefreshUnit_io_rankStati_1_banks_5_canPRE;
  wire  RefreshUnit_io_rankStati_1_banks_6_canPRE;
  wire  RefreshUnit_io_rankStati_1_banks_7_canPRE;
  wire  RefreshUnit_io_rankStati_2_canPRE;
  wire  RefreshUnit_io_rankStati_2_canREF;
  wire  RefreshUnit_io_rankStati_2_wantREF;
  wire  RefreshUnit_io_rankStati_2_banks_0_canPRE;
  wire  RefreshUnit_io_rankStati_2_banks_1_canPRE;
  wire  RefreshUnit_io_rankStati_2_banks_2_canPRE;
  wire  RefreshUnit_io_rankStati_2_banks_3_canPRE;
  wire  RefreshUnit_io_rankStati_2_banks_4_canPRE;
  wire  RefreshUnit_io_rankStati_2_banks_5_canPRE;
  wire  RefreshUnit_io_rankStati_2_banks_6_canPRE;
  wire  RefreshUnit_io_rankStati_2_banks_7_canPRE;
  wire  RefreshUnit_io_rankStati_3_canPRE;
  wire  RefreshUnit_io_rankStati_3_canREF;
  wire  RefreshUnit_io_rankStati_3_wantREF;
  wire  RefreshUnit_io_rankStati_3_banks_0_canPRE;
  wire  RefreshUnit_io_rankStati_3_banks_1_canPRE;
  wire  RefreshUnit_io_rankStati_3_banks_2_canPRE;
  wire  RefreshUnit_io_rankStati_3_banks_3_canPRE;
  wire  RefreshUnit_io_rankStati_3_banks_4_canPRE;
  wire  RefreshUnit_io_rankStati_3_banks_5_canPRE;
  wire  RefreshUnit_io_rankStati_3_banks_6_canPRE;
  wire  RefreshUnit_io_rankStati_3_banks_7_canPRE;
  wire [3:0] RefreshUnit_io_ranksInUse;
  wire  RefreshUnit_io_suggestREF;
  wire [1:0] RefreshUnit_io_refRankAddr;
  wire  RefreshUnit_io_suggestPRE;
  wire [1:0] RefreshUnit_io_preRankAddr;
  wire [2:0] RefreshUnit_io_preBankAddr;
  wire  cmdMonitor_clock;
  wire  cmdMonitor_reset;
  wire [2:0] cmdMonitor_io_cmd;
  wire [1:0] cmdMonitor_io_rank;
  wire [2:0] cmdMonitor_io_bank;
  wire [25:0] cmdMonitor_io_row;
  wire  cmdMonitor_io_autoPRE;
  wire  cmdMonitor_targetFire;
  wire  powerStats_powerMonitor_clock;
  wire  powerStats_powerMonitor_reset;
  wire [31:0] powerStats_powerMonitor_io_stats_allPreCycles;
  wire [31:0] powerStats_powerMonitor_io_stats_numCASR;
  wire [31:0] powerStats_powerMonitor_io_stats_numCASW;
  wire [31:0] powerStats_powerMonitor_io_stats_numACT;
  wire  powerStats_powerMonitor_io_rankState_state;
  wire  powerStats_powerMonitor_io_rankState_banks_0_canACT;
  wire  powerStats_powerMonitor_io_rankState_banks_1_canACT;
  wire  powerStats_powerMonitor_io_rankState_banks_2_canACT;
  wire  powerStats_powerMonitor_io_rankState_banks_3_canACT;
  wire  powerStats_powerMonitor_io_rankState_banks_4_canACT;
  wire  powerStats_powerMonitor_io_rankState_banks_5_canACT;
  wire  powerStats_powerMonitor_io_rankState_banks_6_canACT;
  wire  powerStats_powerMonitor_io_rankState_banks_7_canACT;
  wire [2:0] powerStats_powerMonitor_io_selectedCmd;
  wire  powerStats_powerMonitor_io_cmdUsesThisRank;
  wire  powerStats_powerMonitor_targetFire;
  wire  powerStats_powerMonitor_1_clock;
  wire  powerStats_powerMonitor_1_reset;
  wire [31:0] powerStats_powerMonitor_1_io_stats_allPreCycles;
  wire [31:0] powerStats_powerMonitor_1_io_stats_numCASR;
  wire [31:0] powerStats_powerMonitor_1_io_stats_numCASW;
  wire [31:0] powerStats_powerMonitor_1_io_stats_numACT;
  wire  powerStats_powerMonitor_1_io_rankState_state;
  wire  powerStats_powerMonitor_1_io_rankState_banks_0_canACT;
  wire  powerStats_powerMonitor_1_io_rankState_banks_1_canACT;
  wire  powerStats_powerMonitor_1_io_rankState_banks_2_canACT;
  wire  powerStats_powerMonitor_1_io_rankState_banks_3_canACT;
  wire  powerStats_powerMonitor_1_io_rankState_banks_4_canACT;
  wire  powerStats_powerMonitor_1_io_rankState_banks_5_canACT;
  wire  powerStats_powerMonitor_1_io_rankState_banks_6_canACT;
  wire  powerStats_powerMonitor_1_io_rankState_banks_7_canACT;
  wire [2:0] powerStats_powerMonitor_1_io_selectedCmd;
  wire  powerStats_powerMonitor_1_io_cmdUsesThisRank;
  wire  powerStats_powerMonitor_1_targetFire;
  wire  powerStats_powerMonitor_2_clock;
  wire  powerStats_powerMonitor_2_reset;
  wire [31:0] powerStats_powerMonitor_2_io_stats_allPreCycles;
  wire [31:0] powerStats_powerMonitor_2_io_stats_numCASR;
  wire [31:0] powerStats_powerMonitor_2_io_stats_numCASW;
  wire [31:0] powerStats_powerMonitor_2_io_stats_numACT;
  wire  powerStats_powerMonitor_2_io_rankState_state;
  wire  powerStats_powerMonitor_2_io_rankState_banks_0_canACT;
  wire  powerStats_powerMonitor_2_io_rankState_banks_1_canACT;
  wire  powerStats_powerMonitor_2_io_rankState_banks_2_canACT;
  wire  powerStats_powerMonitor_2_io_rankState_banks_3_canACT;
  wire  powerStats_powerMonitor_2_io_rankState_banks_4_canACT;
  wire  powerStats_powerMonitor_2_io_rankState_banks_5_canACT;
  wire  powerStats_powerMonitor_2_io_rankState_banks_6_canACT;
  wire  powerStats_powerMonitor_2_io_rankState_banks_7_canACT;
  wire [2:0] powerStats_powerMonitor_2_io_selectedCmd;
  wire  powerStats_powerMonitor_2_io_cmdUsesThisRank;
  wire  powerStats_powerMonitor_2_targetFire;
  wire  powerStats_powerMonitor_3_clock;
  wire  powerStats_powerMonitor_3_reset;
  wire [31:0] powerStats_powerMonitor_3_io_stats_allPreCycles;
  wire [31:0] powerStats_powerMonitor_3_io_stats_numCASR;
  wire [31:0] powerStats_powerMonitor_3_io_stats_numCASW;
  wire [31:0] powerStats_powerMonitor_3_io_stats_numACT;
  wire  powerStats_powerMonitor_3_io_rankState_state;
  wire  powerStats_powerMonitor_3_io_rankState_banks_0_canACT;
  wire  powerStats_powerMonitor_3_io_rankState_banks_1_canACT;
  wire  powerStats_powerMonitor_3_io_rankState_banks_2_canACT;
  wire  powerStats_powerMonitor_3_io_rankState_banks_3_canACT;
  wire  powerStats_powerMonitor_3_io_rankState_banks_4_canACT;
  wire  powerStats_powerMonitor_3_io_rankState_banks_5_canACT;
  wire  powerStats_powerMonitor_3_io_rankState_banks_6_canACT;
  wire  powerStats_powerMonitor_3_io_rankState_banks_7_canACT;
  wire [2:0] powerStats_powerMonitor_3_io_selectedCmd;
  wire  powerStats_powerMonitor_3_io_cmdUsesThisRank;
  wire  powerStats_powerMonitor_3_targetFire;
  reg [63:0] tCycle; // @[TimingModel.scala 97:23]
  wire [63:0] _tCycle_T_1 = tCycle + 64'h1; // @[TimingModel.scala 98:20]
  wire  _T_1 = io_tNasti_r_ready & io_tNasti_r_valid; // @[Decoupled.scala 40:37]
  wire  _T_5 = io_tNasti_w_ready & io_tNasti_w_valid; // @[Decoupled.scala 40:37]
  reg [31:0] totalReads; // @[TimingModel.scala 145:29]
  reg [31:0] totalWrites; // @[TimingModel.scala 146:30]
  wire [31:0] _totalReads_T_1 = totalReads + 32'h1; // @[TimingModel.scala 147:54]
  wire [31:0] _totalWrites_T_1 = totalWrites + 32'h1; // @[TimingModel.scala 148:56]
  reg [31:0] totalReadBeats; // @[TimingModel.scala 154:33]
  reg [31:0] totalWriteBeats; // @[TimingModel.scala 155:34]
  wire [31:0] _totalReadBeats_T_1 = totalReadBeats + 32'h1; // @[TimingModel.scala 156:59]
  wire [31:0] _totalWriteBeats_T_1 = totalWriteBeats + 32'h1; // @[TimingModel.scala 157:61]
  reg [31:0] readOutstandingHistogram_0; // @[TimingModel.scala 166:63]
  reg [31:0] readOutstandingHistogram_1; // @[TimingModel.scala 166:63]
  reg [31:0] readOutstandingHistogram_2; // @[TimingModel.scala 166:63]
  reg [31:0] readOutstandingHistogram_3; // @[TimingModel.scala 166:63]
  reg [31:0] writeOutstandingHistogram_0; // @[TimingModel.scala 167:64]
  reg [31:0] writeOutstandingHistogram_1; // @[TimingModel.scala 167:64]
  reg [31:0] writeOutstandingHistogram_2; // @[TimingModel.scala 167:64]
  reg [31:0] writeOutstandingHistogram_3; // @[TimingModel.scala 167:64]
  wire  _T_23 = SatUpDownCounter_io_value <= 4'h0; // @[TimingModel.scala 171:42]
  wire [31:0] _readOutstandingHistogram_0_T_1 = readOutstandingHistogram_0 + 32'h1; // @[TimingModel.scala 172:25]
  wire  _T_28 = SatUpDownCounter_io_value <= 4'h2; // @[TimingModel.scala 171:42]
  wire [31:0] _readOutstandingHistogram_1_T_1 = readOutstandingHistogram_1 + 32'h1; // @[TimingModel.scala 172:25]
  wire  _T_31 = _T_23 | _T_28; // @[TimingModel.scala 174:25]
  wire  _T_33 = SatUpDownCounter_io_value <= 4'h4; // @[TimingModel.scala 171:42]
  wire [31:0] _readOutstandingHistogram_2_T_1 = readOutstandingHistogram_2 + 32'h1; // @[TimingModel.scala 172:25]
  wire  _T_36 = _T_23 | _T_28 | _T_33; // @[TimingModel.scala 174:25]
  wire [31:0] _readOutstandingHistogram_3_T_1 = readOutstandingHistogram_3 + 32'h1; // @[TimingModel.scala 172:25]
  wire  _T_43 = SatUpDownCounter_1_io_value <= 4'h0; // @[TimingModel.scala 171:42]
  wire [31:0] _writeOutstandingHistogram_0_T_1 = writeOutstandingHistogram_0 + 32'h1; // @[TimingModel.scala 172:25]
  wire  _T_48 = SatUpDownCounter_1_io_value <= 4'h2; // @[TimingModel.scala 171:42]
  wire [31:0] _writeOutstandingHistogram_1_T_1 = writeOutstandingHistogram_1 + 32'h1; // @[TimingModel.scala 172:25]
  wire  _T_51 = _T_43 | _T_48; // @[TimingModel.scala 174:25]
  wire  _T_53 = SatUpDownCounter_1_io_value <= 4'h4; // @[TimingModel.scala 171:42]
  wire [31:0] _writeOutstandingHistogram_2_T_1 = writeOutstandingHistogram_2 + 32'h1; // @[TimingModel.scala 172:25]
  wire  _T_56 = _T_43 | _T_48 | _T_53; // @[TimingModel.scala 174:25]
  wire [31:0] _writeOutstandingHistogram_3_T_1 = writeOutstandingHistogram_3 + 32'h1; // @[TimingModel.scala 172:25]
  wire [34:0] _currentReference_next_bits_bankAddr_T = xactionScheduler_io_nextXaction_bits_addr >>
    io_mmReg_bankAddr_offset; // @[Util.scala 63:52]
  wire [34:0] _GEN_482 = {{32'd0}, io_mmReg_bankAddr_mask}; // @[Util.scala 63:63]
  wire [34:0] _currentReference_next_bits_bankAddr_T_1 = _currentReference_next_bits_bankAddr_T & _GEN_482; // @[Util.scala 63:63]
  wire [34:0] _currentReference_next_bits_rowAddr_T = xactionScheduler_io_nextXaction_bits_addr >>
    io_mmReg_rowAddr_offset; // @[Util.scala 63:52]
  wire [34:0] _GEN_483 = {{9'd0}, io_mmReg_rowAddr_mask}; // @[Util.scala 63:63]
  wire [34:0] _currentReference_next_bits_rowAddr_T_1 = _currentReference_next_bits_rowAddr_T & _GEN_483; // @[Util.scala 63:63]
  wire [34:0] _currentReference_next_bits_rankAddr_T = xactionScheduler_io_nextXaction_bits_addr >>
    io_mmReg_rankAddr_offset; // @[Util.scala 63:52]
  wire [34:0] _GEN_484 = {{33'd0}, io_mmReg_rankAddr_mask}; // @[Util.scala 63:63]
  wire [34:0] _currentReference_next_bits_rankAddr_T_1 = _currentReference_next_bits_rankAddr_T & _GEN_484; // @[Util.scala 63:63]
  wire  _GEN_167 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_1_state :
    rankStateTrackers_3_io_rank_banks_0_state; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_173 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_2_state : _GEN_167; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_179 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_3_state : _GEN_173; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_185 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_4_state : _GEN_179; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_191 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_5_state : _GEN_185; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_197 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_6_state : _GEN_191; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_3_state = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_7_state :
    _GEN_197; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_119 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_1_state :
    rankStateTrackers_2_io_rank_banks_0_state; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_125 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_2_state : _GEN_119; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_131 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_3_state : _GEN_125; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_137 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_4_state : _GEN_131; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_143 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_5_state : _GEN_137; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_149 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_6_state : _GEN_143; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_2_state = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_7_state :
    _GEN_149; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_71 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_1_state :
    rankStateTrackers_1_io_rank_banks_0_state; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_77 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_2_state : _GEN_71; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_83 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_3_state : _GEN_77; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_89 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_4_state : _GEN_83; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_95 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_5_state : _GEN_89; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_101 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_6_state : _GEN_95; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_1_state = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_7_state :
    _GEN_101; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_23 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_1_state :
    rankStateTrackers_0_io_rank_banks_0_state; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_29 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_2_state : _GEN_23; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_35 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_3_state : _GEN_29; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_41 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_4_state : _GEN_35; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_47 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_5_state : _GEN_41; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_53 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_6_state : _GEN_47; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_0_state = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_7_state :
    _GEN_53; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_215 = 2'h1 == currentReference_io_deq_bits_rankAddr ? bankMuxes_1_state : bankMuxes_0_state; // @[]
  wire  _GEN_221 = 2'h2 == currentReference_io_deq_bits_rankAddr ? bankMuxes_2_state : _GEN_215; // @[]
  wire  currentBank_state = 2'h3 == currentReference_io_deq_bits_rankAddr ? bankMuxes_3_state : _GEN_221; // @[]
  wire [25:0] _GEN_160 = rankStateTrackers_3_io_rank_banks_0_openRow; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_166 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_1_openRow :
    _GEN_160; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_172 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_2_openRow :
    _GEN_166; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_178 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_3_openRow :
    _GEN_172; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_184 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_4_openRow :
    _GEN_178; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_190 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_5_openRow :
    _GEN_184; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_196 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_6_openRow :
    _GEN_190; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] bankMuxes_3_openRow = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_3_io_rank_banks_7_openRow : _GEN_196; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_112 = rankStateTrackers_2_io_rank_banks_0_openRow; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_118 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_1_openRow :
    _GEN_112; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_124 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_2_openRow :
    _GEN_118; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_130 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_3_openRow :
    _GEN_124; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_136 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_4_openRow :
    _GEN_130; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_142 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_5_openRow :
    _GEN_136; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_148 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_6_openRow :
    _GEN_142; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] bankMuxes_2_openRow = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_2_io_rank_banks_7_openRow : _GEN_148; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_64 = rankStateTrackers_1_io_rank_banks_0_openRow; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_70 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_1_openRow :
    _GEN_64; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_76 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_2_openRow :
    _GEN_70; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_82 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_3_openRow :
    _GEN_76; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_88 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_4_openRow :
    _GEN_82; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_94 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_5_openRow :
    _GEN_88; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_100 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_6_openRow :
    _GEN_94; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] bankMuxes_1_openRow = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_1_io_rank_banks_7_openRow : _GEN_100; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_16 = rankStateTrackers_0_io_rank_banks_0_openRow; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_22 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_1_openRow :
    _GEN_16; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_28 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_2_openRow :
    _GEN_22; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_34 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_3_openRow :
    _GEN_28; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_40 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_4_openRow :
    _GEN_34; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_46 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_5_openRow :
    _GEN_40; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_52 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_6_openRow :
    _GEN_46; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] bankMuxes_0_openRow = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_0_io_rank_banks_7_openRow : _GEN_52; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire [25:0] _GEN_214 = 2'h1 == currentReference_io_deq_bits_rankAddr ? bankMuxes_1_openRow : bankMuxes_0_openRow; // @[]
  wire [25:0] _GEN_220 = 2'h2 == currentReference_io_deq_bits_rankAddr ? bankMuxes_2_openRow : _GEN_214; // @[]
  wire [25:0] currentBank_openRow = 2'h3 == currentReference_io_deq_bits_rankAddr ? bankMuxes_3_openRow : _GEN_220; // @[]
  wire  currentRowHit = currentBank_state & currentReference_io_deq_bits_rowAddr == currentBank_openRow; // @[FIFOMASModel.scala 79:57]
  wire  _canCASR_T_2 = ~currentReference_io_deq_bits_xaction_isWrite; // @[FIFOMASModel.scala 87:5]
  wire  _canCASR_T_3 = backend_io_newRead_ready & currentReference_io_deq_valid & currentRowHit & _canCASR_T_2; // @[FIFOMASModel.scala 86:85]
  wire  _GEN_163 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_1_canCASR :
    rankStateTrackers_3_io_rank_banks_0_canCASR; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_169 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_2_canCASR :
    _GEN_163; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_175 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_3_canCASR :
    _GEN_169; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_181 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_4_canCASR :
    _GEN_175; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_187 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_5_canCASR :
    _GEN_181; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_193 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_6_canCASR :
    _GEN_187; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_3_canCASR = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_3_io_rank_banks_7_canCASR : _GEN_193; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_115 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_1_canCASR :
    rankStateTrackers_2_io_rank_banks_0_canCASR; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_121 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_2_canCASR :
    _GEN_115; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_127 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_3_canCASR :
    _GEN_121; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_133 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_4_canCASR :
    _GEN_127; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_139 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_5_canCASR :
    _GEN_133; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_145 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_6_canCASR :
    _GEN_139; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_2_canCASR = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_2_io_rank_banks_7_canCASR : _GEN_145; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_67 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_1_canCASR :
    rankStateTrackers_1_io_rank_banks_0_canCASR; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_73 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_2_canCASR : _GEN_67; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_79 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_3_canCASR : _GEN_73; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_85 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_4_canCASR : _GEN_79; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_91 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_5_canCASR : _GEN_85; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_97 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_6_canCASR : _GEN_91; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_1_canCASR = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_1_io_rank_banks_7_canCASR : _GEN_97; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_19 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_1_canCASR :
    rankStateTrackers_0_io_rank_banks_0_canCASR; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_25 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_2_canCASR : _GEN_19; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_31 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_3_canCASR : _GEN_25; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_37 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_4_canCASR : _GEN_31; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_43 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_5_canCASR : _GEN_37; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_49 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_6_canCASR : _GEN_43; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_0_canCASR = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_0_io_rank_banks_7_canCASR : _GEN_49; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_211 = 2'h1 == currentReference_io_deq_bits_rankAddr ? bankMuxes_1_canCASR : bankMuxes_0_canCASR; // @[]
  wire  _GEN_217 = 2'h2 == currentReference_io_deq_bits_rankAddr ? bankMuxes_2_canCASR : _GEN_211; // @[]
  wire  currentBank_canCASR = 2'h3 == currentReference_io_deq_bits_rankAddr ? bankMuxes_3_canCASR : _GEN_217; // @[]
  wire  _currentRank_WIRE_3_canCASR = rankStateTrackers_3_io_rank_canCASR; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_2_canCASR = rankStateTrackers_2_io_rank_canCASR; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_1_canCASR = rankStateTrackers_1_io_rank_canCASR; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_0_canCASR = rankStateTrackers_0_io_rank_canCASR; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _GEN_284 = 2'h1 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_1_canCASR :
    _currentRank_WIRE_0_canCASR; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_339 = 2'h2 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_2_canCASR : _GEN_284; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_394 = 2'h3 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_3_canCASR : _GEN_339; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _currentRank_WIRE_3_wantREF = rankStateTrackers_3_io_rank_wantREF; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_2_wantREF = rankStateTrackers_2_io_rank_wantREF; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_1_wantREF = rankStateTrackers_1_io_rank_wantREF; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_0_wantREF = rankStateTrackers_0_io_rank_wantREF; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _GEN_288 = 2'h1 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_1_wantREF :
    _currentRank_WIRE_0_wantREF; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_343 = 2'h2 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_2_wantREF : _GEN_288; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_398 = 2'h3 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_3_wantREF : _GEN_343; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _canCASR_T_6 = ~_GEN_398; // @[FIFOMASModel.scala 88:5]
  wire  canCASR = _canCASR_T_3 & currentBank_canCASR & _GEN_394 & _canCASR_T_6; // @[FIFOMASModel.scala 87:90]
  wire  _canCASW_T_1 = backend_io_newWrite_ready & currentReference_io_deq_valid & currentRowHit; // @[FIFOMASModel.scala 82:69]
  wire  _GEN_162 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_1_canCASW :
    rankStateTrackers_3_io_rank_banks_0_canCASW; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_168 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_2_canCASW :
    _GEN_162; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_174 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_3_canCASW :
    _GEN_168; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_180 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_4_canCASW :
    _GEN_174; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_186 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_5_canCASW :
    _GEN_180; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_192 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_6_canCASW :
    _GEN_186; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_3_canCASW = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_3_io_rank_banks_7_canCASW : _GEN_192; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_114 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_1_canCASW :
    rankStateTrackers_2_io_rank_banks_0_canCASW; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_120 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_2_canCASW :
    _GEN_114; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_126 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_3_canCASW :
    _GEN_120; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_132 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_4_canCASW :
    _GEN_126; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_138 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_5_canCASW :
    _GEN_132; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_144 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_6_canCASW :
    _GEN_138; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_2_canCASW = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_2_io_rank_banks_7_canCASW : _GEN_144; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_66 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_1_canCASW :
    rankStateTrackers_1_io_rank_banks_0_canCASW; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_72 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_2_canCASW : _GEN_66; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_78 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_3_canCASW : _GEN_72; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_84 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_4_canCASW : _GEN_78; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_90 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_5_canCASW : _GEN_84; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_96 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_6_canCASW : _GEN_90; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_1_canCASW = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_1_io_rank_banks_7_canCASW : _GEN_96; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_18 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_1_canCASW :
    rankStateTrackers_0_io_rank_banks_0_canCASW; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_24 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_2_canCASW : _GEN_18; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_30 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_3_canCASW : _GEN_24; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_36 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_4_canCASW : _GEN_30; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_42 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_5_canCASW : _GEN_36; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_48 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_6_canCASW : _GEN_42; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_0_canCASW = 3'h7 == currentReference_io_deq_bits_bankAddr ?
    rankStateTrackers_0_io_rank_banks_7_canCASW : _GEN_48; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_210 = 2'h1 == currentReference_io_deq_bits_rankAddr ? bankMuxes_1_canCASW : bankMuxes_0_canCASW; // @[]
  wire  _GEN_216 = 2'h2 == currentReference_io_deq_bits_rankAddr ? bankMuxes_2_canCASW : _GEN_210; // @[]
  wire  currentBank_canCASW = 2'h3 == currentReference_io_deq_bits_rankAddr ? bankMuxes_3_canCASW : _GEN_216; // @[]
  wire  _currentRank_WIRE_3_canCASW = rankStateTrackers_3_io_rank_canCASW; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_2_canCASW = rankStateTrackers_2_io_rank_canCASW; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_1_canCASW = rankStateTrackers_1_io_rank_canCASW; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_0_canCASW = rankStateTrackers_0_io_rank_canCASW; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _GEN_283 = 2'h1 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_1_canCASW :
    _currentRank_WIRE_0_canCASW; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_338 = 2'h2 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_2_canCASW : _GEN_283; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_393 = 2'h3 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_3_canCASW : _GEN_338; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _canCASW_T_4 = _canCASW_T_1 & currentReference_io_deq_bits_xaction_isWrite & currentBank_canCASW & _GEN_393; // @[FIFOMASModel.scala 83:83]
  wire  canCASW = _canCASW_T_4 & _canCASR_T_6; // @[FIFOMASModel.scala 84:25]
  wire  _GEN_165 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_1_canACT :
    rankStateTrackers_3_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_171 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_2_canACT : _GEN_165
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_177 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_3_canACT : _GEN_171
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_183 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_4_canACT : _GEN_177
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_189 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_5_canACT : _GEN_183
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_195 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_6_canACT : _GEN_189
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_3_canACT = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_7_canACT
     : _GEN_195; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_117 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_1_canACT :
    rankStateTrackers_2_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_123 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_2_canACT : _GEN_117
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_129 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_3_canACT : _GEN_123
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_135 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_4_canACT : _GEN_129
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_141 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_5_canACT : _GEN_135
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_147 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_6_canACT : _GEN_141
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_2_canACT = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_7_canACT
     : _GEN_147; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_69 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_1_canACT :
    rankStateTrackers_1_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_75 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_2_canACT : _GEN_69; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_81 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_3_canACT : _GEN_75; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_87 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_4_canACT : _GEN_81; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_93 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_5_canACT : _GEN_87; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_99 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_6_canACT : _GEN_93; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_1_canACT = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_7_canACT
     : _GEN_99; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_21 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_1_canACT :
    rankStateTrackers_0_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_27 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_2_canACT : _GEN_21; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_33 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_3_canACT : _GEN_27; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_39 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_4_canACT : _GEN_33; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_45 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_5_canACT : _GEN_39; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_51 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_6_canACT : _GEN_45; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_0_canACT = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_7_canACT
     : _GEN_51; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_213 = 2'h1 == currentReference_io_deq_bits_rankAddr ? bankMuxes_1_canACT : bankMuxes_0_canACT; // @[]
  wire  _GEN_219 = 2'h2 == currentReference_io_deq_bits_rankAddr ? bankMuxes_2_canACT : _GEN_213; // @[]
  wire  currentBank_canACT = 2'h3 == currentReference_io_deq_bits_rankAddr ? bankMuxes_3_canACT : _GEN_219; // @[]
  wire  _currentRank_WIRE_3_canACT = rankStateTrackers_3_io_rank_canACT; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_2_canACT = rankStateTrackers_2_io_rank_canACT; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_1_canACT = rankStateTrackers_1_io_rank_canACT; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_0_canACT = rankStateTrackers_0_io_rank_canACT; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _GEN_286 = 2'h1 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_1_canACT :
    _currentRank_WIRE_0_canACT; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_341 = 2'h2 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_2_canACT : _GEN_286; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_396 = 2'h3 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_3_canACT : _GEN_341; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _T_69 = currentReference_io_deq_valid & currentBank_canACT & _GEN_396 & _canCASR_T_6; // @[FIFOMASModel.scala 107:84]
  wire  _GEN_164 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_1_canPRE :
    rankStateTrackers_3_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_170 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_2_canPRE : _GEN_164
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_176 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_3_canPRE : _GEN_170
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_182 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_4_canPRE : _GEN_176
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_188 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_5_canPRE : _GEN_182
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_194 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_6_canPRE : _GEN_188
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_3_canPRE = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_3_io_rank_banks_7_canPRE
     : _GEN_194; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_116 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_1_canPRE :
    rankStateTrackers_2_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_122 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_2_canPRE : _GEN_116
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_128 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_3_canPRE : _GEN_122
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_134 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_4_canPRE : _GEN_128
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_140 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_5_canPRE : _GEN_134
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_146 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_6_canPRE : _GEN_140
    ; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_2_canPRE = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_2_io_rank_banks_7_canPRE
     : _GEN_146; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_68 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_1_canPRE :
    rankStateTrackers_1_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_74 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_2_canPRE : _GEN_68; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_80 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_3_canPRE : _GEN_74; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_86 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_4_canPRE : _GEN_80; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_92 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_5_canPRE : _GEN_86; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_98 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_6_canPRE : _GEN_92; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_1_canPRE = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_1_io_rank_banks_7_canPRE
     : _GEN_98; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_20 = 3'h1 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_1_canPRE :
    rankStateTrackers_0_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_26 = 3'h2 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_2_canPRE : _GEN_20; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_32 = 3'h3 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_3_canPRE : _GEN_26; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_38 = 3'h4 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_4_canPRE : _GEN_32; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_44 = 3'h5 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_5_canPRE : _GEN_38; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_50 = 3'h6 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_6_canPRE : _GEN_44; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  bankMuxes_0_canPRE = 3'h7 == currentReference_io_deq_bits_bankAddr ? rankStateTrackers_0_io_rank_banks_7_canPRE
     : _GEN_50; // @[FIFOMASModel.scala 71:26 FIFOMASModel.scala 71:26]
  wire  _GEN_212 = 2'h1 == currentReference_io_deq_bits_rankAddr ? bankMuxes_1_canPRE : bankMuxes_0_canPRE; // @[]
  wire  _GEN_218 = 2'h2 == currentReference_io_deq_bits_rankAddr ? bankMuxes_2_canPRE : _GEN_212; // @[]
  wire  currentBank_canPRE = 2'h3 == currentReference_io_deq_bits_rankAddr ? bankMuxes_3_canPRE : _GEN_218; // @[]
  wire  _currentRank_WIRE_3_canPRE = rankStateTrackers_3_io_rank_canPRE; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_2_canPRE = rankStateTrackers_2_io_rank_canPRE; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_1_canPRE = rankStateTrackers_1_io_rank_canPRE; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _currentRank_WIRE_0_canPRE = rankStateTrackers_0_io_rank_canPRE; // @[FIFOMASModel.scala 70:28 FIFOMASModel.scala 70:28]
  wire  _GEN_285 = 2'h1 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_1_canPRE :
    _currentRank_WIRE_0_canPRE; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_340 = 2'h2 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_2_canPRE : _GEN_285; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire  _GEN_395 = 2'h3 == currentReference_io_deq_bits_rankAddr ? _currentRank_WIRE_3_canPRE : _GEN_340; // @[FIFOMASModel.scala 83:83 FIFOMASModel.scala 83:83]
  wire [2:0] _GEN_448 = currentReference_io_deq_valid & ~currentRowHit & currentBank_canPRE & _GEN_395 ? 3'h2 : 3'h0; // @[FIFOMASModel.scala 109:103 FIFOMASModel.scala 110:19]
  wire [2:0] _GEN_449 = currentReference_io_deq_valid & currentBank_canACT & _GEN_396 & _canCASR_T_6 ? 3'h1 : _GEN_448; // @[FIFOMASModel.scala 107:109 FIFOMASModel.scala 108:19]
  wire [2:0] _GEN_450 = canCASW ? 3'h3 : _GEN_449; // @[FIFOMASModel.scala 105:26 FIFOMASModel.scala 106:19]
  wire [2:0] _GEN_451 = canCASR ? 3'h4 : _GEN_450; // @[FIFOMASModel.scala 103:20 FIFOMASModel.scala 104:19]
  wire [2:0] _GEN_452 = _T_69 ? 3'h1 : 3'h0; // @[FIFOMASModel.scala 119:109 FIFOMASModel.scala 120:19]
  wire [2:0] _GEN_453 = canCASW ? 3'h3 : _GEN_452; // @[FIFOMASModel.scala 116:26 FIFOMASModel.scala 117:19]
  wire [2:0] _GEN_455 = canCASR ? 3'h4 : _GEN_453; // @[FIFOMASModel.scala 113:20 FIFOMASModel.scala 114:19]
  wire [2:0] _GEN_457 = io_mmReg_openPagePolicy ? _GEN_451 : _GEN_455; // @[FIFOMASModel.scala 102:39]
  wire [2:0] _GEN_459 = RefreshUnit_io_suggestPRE ? 3'h2 : _GEN_457; // @[FIFOMASModel.scala 98:39 FIFOMASModel.scala 99:17]
  wire [2:0] selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  wire  memReqDone = selectedCmd == 3'h4 | selectedCmd == 3'h3; // @[FIFOMASModel.scala 62:46]
  wire [2:0] _GEN_461 = RefreshUnit_io_suggestPRE ? RefreshUnit_io_preBankAddr : currentReference_io_deq_bits_bankAddr; // @[FIFOMASModel.scala 98:39 FIFOMASModel.scala 101:13]
  wire [2:0] cmdBank = RefreshUnit_io_suggestREF ? currentReference_io_deq_bits_bankAddr : _GEN_461; // @[FIFOMASModel.scala 95:33]
  wire [1:0] _T_64 = io_mmReg_rankAddr_mask[0] ? 2'h3 : 2'h1; // @[Mux.scala 98:16]
  wire  _GEN_456 = canCASR | canCASW; // @[FIFOMASModel.scala 113:20 FIFOMASModel.scala 115:18]
  wire  _GEN_458 = io_mmReg_openPagePolicy ? 1'h0 : _GEN_456; // @[FIFOMASModel.scala 102:39]
  wire [1:0] _GEN_460 = RefreshUnit_io_suggestPRE ? RefreshUnit_io_preRankAddr : currentReference_io_deq_bits_rankAddr; // @[FIFOMASModel.scala 98:39 FIFOMASModel.scala 100:13]
  wire  _GEN_462 = RefreshUnit_io_suggestPRE ? 1'h0 : _GEN_458; // @[FIFOMASModel.scala 98:39]
  wire [1:0] cmdRank = RefreshUnit_io_suggestREF ? RefreshUnit_io_refRankAddr : _GEN_460; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 97:13]
  wire [3:0] _T_78 = 4'h1 << cmdRank; // @[OneHot.scala 58:35]
  wire [6:0] _backend_io_readLatency_T_1 = io_mmReg_dramTimings_tCAS + io_mmReg_dramTimings_tAL; // @[FIFOMASModel.scala 144:42]
  wire [11:0] _GEN_485 = {{5'd0}, _backend_io_readLatency_T_1}; // @[FIFOMASModel.scala 144:56]
  IdentityModule nastiReqIden (
    .io_in_aw_ready(nastiReqIden_io_in_aw_ready),
    .io_in_aw_valid(nastiReqIden_io_in_aw_valid),
    .io_in_aw_bits_addr(nastiReqIden_io_in_aw_bits_addr),
    .io_in_aw_bits_id(nastiReqIden_io_in_aw_bits_id),
    .io_in_w_ready(nastiReqIden_io_in_w_ready),
    .io_in_w_valid(nastiReqIden_io_in_w_valid),
    .io_in_w_bits_last(nastiReqIden_io_in_w_bits_last),
    .io_in_ar_ready(nastiReqIden_io_in_ar_ready),
    .io_in_ar_valid(nastiReqIden_io_in_ar_valid),
    .io_in_ar_bits_addr(nastiReqIden_io_in_ar_bits_addr),
    .io_in_ar_bits_id(nastiReqIden_io_in_ar_bits_id),
    .io_out_aw_ready(nastiReqIden_io_out_aw_ready),
    .io_out_aw_valid(nastiReqIden_io_out_aw_valid),
    .io_out_aw_bits_addr(nastiReqIden_io_out_aw_bits_addr),
    .io_out_aw_bits_id(nastiReqIden_io_out_aw_bits_id),
    .io_out_w_ready(nastiReqIden_io_out_w_ready),
    .io_out_w_valid(nastiReqIden_io_out_w_valid),
    .io_out_w_bits_last(nastiReqIden_io_out_w_bits_last),
    .io_out_ar_ready(nastiReqIden_io_out_ar_ready),
    .io_out_ar_valid(nastiReqIden_io_out_ar_valid),
    .io_out_ar_bits_addr(nastiReqIden_io_out_ar_bits_addr),
    .io_out_ar_bits_id(nastiReqIden_io_out_ar_bits_id)
  );
  MemoryModelMonitor monitor (
    .clock(monitor_clock),
    .reset(monitor_reset),
    .axi4_aw_ready(monitor_axi4_aw_ready),
    .axi4_aw_valid(monitor_axi4_aw_valid),
    .axi4_aw_bits_len(monitor_axi4_aw_bits_len),
    .axi4_ar_ready(monitor_axi4_ar_ready),
    .axi4_ar_valid(monitor_axi4_ar_valid),
    .axi4_ar_bits_len(monitor_axi4_ar_bits_len),
    .targetFire(monitor_targetFire)
  );
  SatUpDownCounter_8 SatUpDownCounter (
    .clock(SatUpDownCounter_clock),
    .reset(SatUpDownCounter_reset),
    .io_inc(SatUpDownCounter_io_inc),
    .io_dec(SatUpDownCounter_io_dec),
    .io_value(SatUpDownCounter_io_value),
    .io_full(SatUpDownCounter_io_full),
    .io_empty(SatUpDownCounter_io_empty),
    .targetFire(SatUpDownCounter_targetFire)
  );
  SatUpDownCounter_8 SatUpDownCounter_1 (
    .clock(SatUpDownCounter_1_clock),
    .reset(SatUpDownCounter_1_reset),
    .io_inc(SatUpDownCounter_1_io_inc),
    .io_dec(SatUpDownCounter_1_io_dec),
    .io_value(SatUpDownCounter_1_io_value),
    .io_full(SatUpDownCounter_1_io_full),
    .io_empty(SatUpDownCounter_1_io_empty),
    .targetFire(SatUpDownCounter_1_targetFire)
  );
  SatUpDownCounter_8 SatUpDownCounter_2 (
    .clock(SatUpDownCounter_2_clock),
    .reset(SatUpDownCounter_2_reset),
    .io_inc(SatUpDownCounter_2_io_inc),
    .io_dec(SatUpDownCounter_2_io_dec),
    .io_value(SatUpDownCounter_2_io_value),
    .io_full(SatUpDownCounter_2_io_full),
    .io_empty(SatUpDownCounter_2_io_empty),
    .targetFire(SatUpDownCounter_2_targetFire)
  );
  AXI4Releaser xactionRelease (
    .clock(xactionRelease_clock),
    .reset(xactionRelease_reset),
    .io_b_ready(xactionRelease_io_b_ready),
    .io_b_valid(xactionRelease_io_b_valid),
    .io_b_bits_id(xactionRelease_io_b_bits_id),
    .io_r_ready(xactionRelease_io_r_ready),
    .io_r_valid(xactionRelease_io_r_valid),
    .io_r_bits_data(xactionRelease_io_r_bits_data),
    .io_r_bits_last(xactionRelease_io_r_bits_last),
    .io_r_bits_id(xactionRelease_io_r_bits_id),
    .io_egressReq_b_valid(xactionRelease_io_egressReq_b_valid),
    .io_egressReq_b_bits(xactionRelease_io_egressReq_b_bits),
    .io_egressReq_r_valid(xactionRelease_io_egressReq_r_valid),
    .io_egressReq_r_bits(xactionRelease_io_egressReq_r_bits),
    .io_egressResp_bBits_id(xactionRelease_io_egressResp_bBits_id),
    .io_egressResp_bReady(xactionRelease_io_egressResp_bReady),
    .io_egressResp_rBits_data(xactionRelease_io_egressResp_rBits_data),
    .io_egressResp_rBits_last(xactionRelease_io_egressResp_rBits_last),
    .io_egressResp_rBits_id(xactionRelease_io_egressResp_rBits_id),
    .io_egressResp_rReady(xactionRelease_io_egressResp_rReady),
    .io_nextRead_ready(xactionRelease_io_nextRead_ready),
    .io_nextRead_valid(xactionRelease_io_nextRead_valid),
    .io_nextRead_bits_id(xactionRelease_io_nextRead_bits_id),
    .io_nextWrite_ready(xactionRelease_io_nextWrite_ready),
    .io_nextWrite_valid(xactionRelease_io_nextWrite_valid),
    .io_nextWrite_bits_id(xactionRelease_io_nextWrite_bits_id),
    .targetFire(xactionRelease_targetFire)
  );
  DRAMBackend backend (
    .clock(backend_clock),
    .reset(backend_reset),
    .io_newRead_ready(backend_io_newRead_ready),
    .io_newRead_valid(backend_io_newRead_valid),
    .io_newRead_bits_id(backend_io_newRead_bits_id),
    .io_newWrite_ready(backend_io_newWrite_ready),
    .io_newWrite_valid(backend_io_newWrite_valid),
    .io_newWrite_bits_id(backend_io_newWrite_bits_id),
    .io_completedRead_ready(backend_io_completedRead_ready),
    .io_completedRead_valid(backend_io_completedRead_valid),
    .io_completedRead_bits_id(backend_io_completedRead_bits_id),
    .io_completedWrite_ready(backend_io_completedWrite_ready),
    .io_completedWrite_valid(backend_io_completedWrite_valid),
    .io_completedWrite_bits_id(backend_io_completedWrite_bits_id),
    .io_readLatency(backend_io_readLatency),
    .io_tCycle(backend_io_tCycle),
    .targetFire(backend_targetFire)
  );
  UnifiedFIFOXactionScheduler xactionScheduler (
    .clock(xactionScheduler_clock),
    .reset(xactionScheduler_reset),
    .io_req_aw_ready(xactionScheduler_io_req_aw_ready),
    .io_req_aw_valid(xactionScheduler_io_req_aw_valid),
    .io_req_aw_bits_addr(xactionScheduler_io_req_aw_bits_addr),
    .io_req_aw_bits_id(xactionScheduler_io_req_aw_bits_id),
    .io_req_w_ready(xactionScheduler_io_req_w_ready),
    .io_req_w_valid(xactionScheduler_io_req_w_valid),
    .io_req_w_bits_last(xactionScheduler_io_req_w_bits_last),
    .io_req_ar_ready(xactionScheduler_io_req_ar_ready),
    .io_req_ar_valid(xactionScheduler_io_req_ar_valid),
    .io_req_ar_bits_addr(xactionScheduler_io_req_ar_bits_addr),
    .io_req_ar_bits_id(xactionScheduler_io_req_ar_bits_id),
    .io_nextXaction_ready(xactionScheduler_io_nextXaction_ready),
    .io_nextXaction_valid(xactionScheduler_io_nextXaction_valid),
    .io_nextXaction_bits_xaction_id(xactionScheduler_io_nextXaction_bits_xaction_id),
    .io_nextXaction_bits_xaction_isWrite(xactionScheduler_io_nextXaction_bits_xaction_isWrite),
    .io_nextXaction_bits_addr(xactionScheduler_io_nextXaction_bits_addr),
    .io_pendingWReq(xactionScheduler_io_pendingWReq),
    .io_pendingAWReq(xactionScheduler_io_pendingAWReq),
    .targetFire(xactionScheduler_targetFire)
  );
  Queue_16_0 currentReference (
    .clock(currentReference_clock),
    .reset(currentReference_reset),
    .io_enq_ready(currentReference_io_enq_ready),
    .io_enq_valid(currentReference_io_enq_valid),
    .io_enq_bits_xaction_id(currentReference_io_enq_bits_xaction_id),
    .io_enq_bits_xaction_isWrite(currentReference_io_enq_bits_xaction_isWrite),
    .io_enq_bits_rowAddr(currentReference_io_enq_bits_rowAddr),
    .io_enq_bits_bankAddr(currentReference_io_enq_bits_bankAddr),
    .io_enq_bits_rankAddr(currentReference_io_enq_bits_rankAddr),
    .io_deq_ready(currentReference_io_deq_ready),
    .io_deq_valid(currentReference_io_deq_valid),
    .io_deq_bits_xaction_id(currentReference_io_deq_bits_xaction_id),
    .io_deq_bits_xaction_isWrite(currentReference_io_deq_bits_xaction_isWrite),
    .io_deq_bits_rowAddr(currentReference_io_deq_bits_rowAddr),
    .io_deq_bits_bankAddr(currentReference_io_deq_bits_bankAddr),
    .io_deq_bits_rankAddr(currentReference_io_deq_bits_rankAddr),
    .targetFire(currentReference_targetFire)
  );
  DownCounter cmdBusBusy (
    .clock(cmdBusBusy_clock),
    .reset(cmdBusBusy_reset),
    .io_set_valid(cmdBusBusy_io_set_valid),
    .io_set_bits(cmdBusBusy_io_set_bits),
    .io_idle(cmdBusBusy_io_idle),
    .targetFire(cmdBusBusy_targetFire)
  );
  RankStateTracker rankStateTrackers_0 (
    .clock(rankStateTrackers_0_clock),
    .reset(rankStateTrackers_0_reset),
    .io_timings_tAL(rankStateTrackers_0_io_timings_tAL),
    .io_timings_tCAS(rankStateTrackers_0_io_timings_tCAS),
    .io_timings_tCWD(rankStateTrackers_0_io_timings_tCWD),
    .io_timings_tCCD(rankStateTrackers_0_io_timings_tCCD),
    .io_timings_tFAW(rankStateTrackers_0_io_timings_tFAW),
    .io_timings_tRAS(rankStateTrackers_0_io_timings_tRAS),
    .io_timings_tREFI(rankStateTrackers_0_io_timings_tREFI),
    .io_timings_tRC(rankStateTrackers_0_io_timings_tRC),
    .io_timings_tRCD(rankStateTrackers_0_io_timings_tRCD),
    .io_timings_tRFC(rankStateTrackers_0_io_timings_tRFC),
    .io_timings_tRRD(rankStateTrackers_0_io_timings_tRRD),
    .io_timings_tRP(rankStateTrackers_0_io_timings_tRP),
    .io_timings_tRTP(rankStateTrackers_0_io_timings_tRTP),
    .io_timings_tRTRS(rankStateTrackers_0_io_timings_tRTRS),
    .io_timings_tWR(rankStateTrackers_0_io_timings_tWR),
    .io_timings_tWTR(rankStateTrackers_0_io_timings_tWTR),
    .io_selectedCmd(rankStateTrackers_0_io_selectedCmd),
    .io_autoPRE(rankStateTrackers_0_io_autoPRE),
    .io_cmdRow(rankStateTrackers_0_io_cmdRow),
    .io_rank_canCASW(rankStateTrackers_0_io_rank_canCASW),
    .io_rank_canCASR(rankStateTrackers_0_io_rank_canCASR),
    .io_rank_canPRE(rankStateTrackers_0_io_rank_canPRE),
    .io_rank_canACT(rankStateTrackers_0_io_rank_canACT),
    .io_rank_canREF(rankStateTrackers_0_io_rank_canREF),
    .io_rank_wantREF(rankStateTrackers_0_io_rank_wantREF),
    .io_rank_state(rankStateTrackers_0_io_rank_state),
    .io_rank_banks_0_canCASW(rankStateTrackers_0_io_rank_banks_0_canCASW),
    .io_rank_banks_0_canCASR(rankStateTrackers_0_io_rank_banks_0_canCASR),
    .io_rank_banks_0_canPRE(rankStateTrackers_0_io_rank_banks_0_canPRE),
    .io_rank_banks_0_canACT(rankStateTrackers_0_io_rank_banks_0_canACT),
    .io_rank_banks_0_openRow(rankStateTrackers_0_io_rank_banks_0_openRow),
    .io_rank_banks_0_state(rankStateTrackers_0_io_rank_banks_0_state),
    .io_rank_banks_1_canCASW(rankStateTrackers_0_io_rank_banks_1_canCASW),
    .io_rank_banks_1_canCASR(rankStateTrackers_0_io_rank_banks_1_canCASR),
    .io_rank_banks_1_canPRE(rankStateTrackers_0_io_rank_banks_1_canPRE),
    .io_rank_banks_1_canACT(rankStateTrackers_0_io_rank_banks_1_canACT),
    .io_rank_banks_1_openRow(rankStateTrackers_0_io_rank_banks_1_openRow),
    .io_rank_banks_1_state(rankStateTrackers_0_io_rank_banks_1_state),
    .io_rank_banks_2_canCASW(rankStateTrackers_0_io_rank_banks_2_canCASW),
    .io_rank_banks_2_canCASR(rankStateTrackers_0_io_rank_banks_2_canCASR),
    .io_rank_banks_2_canPRE(rankStateTrackers_0_io_rank_banks_2_canPRE),
    .io_rank_banks_2_canACT(rankStateTrackers_0_io_rank_banks_2_canACT),
    .io_rank_banks_2_openRow(rankStateTrackers_0_io_rank_banks_2_openRow),
    .io_rank_banks_2_state(rankStateTrackers_0_io_rank_banks_2_state),
    .io_rank_banks_3_canCASW(rankStateTrackers_0_io_rank_banks_3_canCASW),
    .io_rank_banks_3_canCASR(rankStateTrackers_0_io_rank_banks_3_canCASR),
    .io_rank_banks_3_canPRE(rankStateTrackers_0_io_rank_banks_3_canPRE),
    .io_rank_banks_3_canACT(rankStateTrackers_0_io_rank_banks_3_canACT),
    .io_rank_banks_3_openRow(rankStateTrackers_0_io_rank_banks_3_openRow),
    .io_rank_banks_3_state(rankStateTrackers_0_io_rank_banks_3_state),
    .io_rank_banks_4_canCASW(rankStateTrackers_0_io_rank_banks_4_canCASW),
    .io_rank_banks_4_canCASR(rankStateTrackers_0_io_rank_banks_4_canCASR),
    .io_rank_banks_4_canPRE(rankStateTrackers_0_io_rank_banks_4_canPRE),
    .io_rank_banks_4_canACT(rankStateTrackers_0_io_rank_banks_4_canACT),
    .io_rank_banks_4_openRow(rankStateTrackers_0_io_rank_banks_4_openRow),
    .io_rank_banks_4_state(rankStateTrackers_0_io_rank_banks_4_state),
    .io_rank_banks_5_canCASW(rankStateTrackers_0_io_rank_banks_5_canCASW),
    .io_rank_banks_5_canCASR(rankStateTrackers_0_io_rank_banks_5_canCASR),
    .io_rank_banks_5_canPRE(rankStateTrackers_0_io_rank_banks_5_canPRE),
    .io_rank_banks_5_canACT(rankStateTrackers_0_io_rank_banks_5_canACT),
    .io_rank_banks_5_openRow(rankStateTrackers_0_io_rank_banks_5_openRow),
    .io_rank_banks_5_state(rankStateTrackers_0_io_rank_banks_5_state),
    .io_rank_banks_6_canCASW(rankStateTrackers_0_io_rank_banks_6_canCASW),
    .io_rank_banks_6_canCASR(rankStateTrackers_0_io_rank_banks_6_canCASR),
    .io_rank_banks_6_canPRE(rankStateTrackers_0_io_rank_banks_6_canPRE),
    .io_rank_banks_6_canACT(rankStateTrackers_0_io_rank_banks_6_canACT),
    .io_rank_banks_6_openRow(rankStateTrackers_0_io_rank_banks_6_openRow),
    .io_rank_banks_6_state(rankStateTrackers_0_io_rank_banks_6_state),
    .io_rank_banks_7_canCASW(rankStateTrackers_0_io_rank_banks_7_canCASW),
    .io_rank_banks_7_canCASR(rankStateTrackers_0_io_rank_banks_7_canCASR),
    .io_rank_banks_7_canPRE(rankStateTrackers_0_io_rank_banks_7_canPRE),
    .io_rank_banks_7_canACT(rankStateTrackers_0_io_rank_banks_7_canACT),
    .io_rank_banks_7_openRow(rankStateTrackers_0_io_rank_banks_7_openRow),
    .io_rank_banks_7_state(rankStateTrackers_0_io_rank_banks_7_state),
    .io_tCycle(rankStateTrackers_0_io_tCycle),
    .io_cmdUsesThisRank(rankStateTrackers_0_io_cmdUsesThisRank),
    .io_cmdBankOH(rankStateTrackers_0_io_cmdBankOH),
    .targetFire(rankStateTrackers_0_targetFire)
  );
  RankStateTracker rankStateTrackers_1 (
    .clock(rankStateTrackers_1_clock),
    .reset(rankStateTrackers_1_reset),
    .io_timings_tAL(rankStateTrackers_1_io_timings_tAL),
    .io_timings_tCAS(rankStateTrackers_1_io_timings_tCAS),
    .io_timings_tCWD(rankStateTrackers_1_io_timings_tCWD),
    .io_timings_tCCD(rankStateTrackers_1_io_timings_tCCD),
    .io_timings_tFAW(rankStateTrackers_1_io_timings_tFAW),
    .io_timings_tRAS(rankStateTrackers_1_io_timings_tRAS),
    .io_timings_tREFI(rankStateTrackers_1_io_timings_tREFI),
    .io_timings_tRC(rankStateTrackers_1_io_timings_tRC),
    .io_timings_tRCD(rankStateTrackers_1_io_timings_tRCD),
    .io_timings_tRFC(rankStateTrackers_1_io_timings_tRFC),
    .io_timings_tRRD(rankStateTrackers_1_io_timings_tRRD),
    .io_timings_tRP(rankStateTrackers_1_io_timings_tRP),
    .io_timings_tRTP(rankStateTrackers_1_io_timings_tRTP),
    .io_timings_tRTRS(rankStateTrackers_1_io_timings_tRTRS),
    .io_timings_tWR(rankStateTrackers_1_io_timings_tWR),
    .io_timings_tWTR(rankStateTrackers_1_io_timings_tWTR),
    .io_selectedCmd(rankStateTrackers_1_io_selectedCmd),
    .io_autoPRE(rankStateTrackers_1_io_autoPRE),
    .io_cmdRow(rankStateTrackers_1_io_cmdRow),
    .io_rank_canCASW(rankStateTrackers_1_io_rank_canCASW),
    .io_rank_canCASR(rankStateTrackers_1_io_rank_canCASR),
    .io_rank_canPRE(rankStateTrackers_1_io_rank_canPRE),
    .io_rank_canACT(rankStateTrackers_1_io_rank_canACT),
    .io_rank_canREF(rankStateTrackers_1_io_rank_canREF),
    .io_rank_wantREF(rankStateTrackers_1_io_rank_wantREF),
    .io_rank_state(rankStateTrackers_1_io_rank_state),
    .io_rank_banks_0_canCASW(rankStateTrackers_1_io_rank_banks_0_canCASW),
    .io_rank_banks_0_canCASR(rankStateTrackers_1_io_rank_banks_0_canCASR),
    .io_rank_banks_0_canPRE(rankStateTrackers_1_io_rank_banks_0_canPRE),
    .io_rank_banks_0_canACT(rankStateTrackers_1_io_rank_banks_0_canACT),
    .io_rank_banks_0_openRow(rankStateTrackers_1_io_rank_banks_0_openRow),
    .io_rank_banks_0_state(rankStateTrackers_1_io_rank_banks_0_state),
    .io_rank_banks_1_canCASW(rankStateTrackers_1_io_rank_banks_1_canCASW),
    .io_rank_banks_1_canCASR(rankStateTrackers_1_io_rank_banks_1_canCASR),
    .io_rank_banks_1_canPRE(rankStateTrackers_1_io_rank_banks_1_canPRE),
    .io_rank_banks_1_canACT(rankStateTrackers_1_io_rank_banks_1_canACT),
    .io_rank_banks_1_openRow(rankStateTrackers_1_io_rank_banks_1_openRow),
    .io_rank_banks_1_state(rankStateTrackers_1_io_rank_banks_1_state),
    .io_rank_banks_2_canCASW(rankStateTrackers_1_io_rank_banks_2_canCASW),
    .io_rank_banks_2_canCASR(rankStateTrackers_1_io_rank_banks_2_canCASR),
    .io_rank_banks_2_canPRE(rankStateTrackers_1_io_rank_banks_2_canPRE),
    .io_rank_banks_2_canACT(rankStateTrackers_1_io_rank_banks_2_canACT),
    .io_rank_banks_2_openRow(rankStateTrackers_1_io_rank_banks_2_openRow),
    .io_rank_banks_2_state(rankStateTrackers_1_io_rank_banks_2_state),
    .io_rank_banks_3_canCASW(rankStateTrackers_1_io_rank_banks_3_canCASW),
    .io_rank_banks_3_canCASR(rankStateTrackers_1_io_rank_banks_3_canCASR),
    .io_rank_banks_3_canPRE(rankStateTrackers_1_io_rank_banks_3_canPRE),
    .io_rank_banks_3_canACT(rankStateTrackers_1_io_rank_banks_3_canACT),
    .io_rank_banks_3_openRow(rankStateTrackers_1_io_rank_banks_3_openRow),
    .io_rank_banks_3_state(rankStateTrackers_1_io_rank_banks_3_state),
    .io_rank_banks_4_canCASW(rankStateTrackers_1_io_rank_banks_4_canCASW),
    .io_rank_banks_4_canCASR(rankStateTrackers_1_io_rank_banks_4_canCASR),
    .io_rank_banks_4_canPRE(rankStateTrackers_1_io_rank_banks_4_canPRE),
    .io_rank_banks_4_canACT(rankStateTrackers_1_io_rank_banks_4_canACT),
    .io_rank_banks_4_openRow(rankStateTrackers_1_io_rank_banks_4_openRow),
    .io_rank_banks_4_state(rankStateTrackers_1_io_rank_banks_4_state),
    .io_rank_banks_5_canCASW(rankStateTrackers_1_io_rank_banks_5_canCASW),
    .io_rank_banks_5_canCASR(rankStateTrackers_1_io_rank_banks_5_canCASR),
    .io_rank_banks_5_canPRE(rankStateTrackers_1_io_rank_banks_5_canPRE),
    .io_rank_banks_5_canACT(rankStateTrackers_1_io_rank_banks_5_canACT),
    .io_rank_banks_5_openRow(rankStateTrackers_1_io_rank_banks_5_openRow),
    .io_rank_banks_5_state(rankStateTrackers_1_io_rank_banks_5_state),
    .io_rank_banks_6_canCASW(rankStateTrackers_1_io_rank_banks_6_canCASW),
    .io_rank_banks_6_canCASR(rankStateTrackers_1_io_rank_banks_6_canCASR),
    .io_rank_banks_6_canPRE(rankStateTrackers_1_io_rank_banks_6_canPRE),
    .io_rank_banks_6_canACT(rankStateTrackers_1_io_rank_banks_6_canACT),
    .io_rank_banks_6_openRow(rankStateTrackers_1_io_rank_banks_6_openRow),
    .io_rank_banks_6_state(rankStateTrackers_1_io_rank_banks_6_state),
    .io_rank_banks_7_canCASW(rankStateTrackers_1_io_rank_banks_7_canCASW),
    .io_rank_banks_7_canCASR(rankStateTrackers_1_io_rank_banks_7_canCASR),
    .io_rank_banks_7_canPRE(rankStateTrackers_1_io_rank_banks_7_canPRE),
    .io_rank_banks_7_canACT(rankStateTrackers_1_io_rank_banks_7_canACT),
    .io_rank_banks_7_openRow(rankStateTrackers_1_io_rank_banks_7_openRow),
    .io_rank_banks_7_state(rankStateTrackers_1_io_rank_banks_7_state),
    .io_tCycle(rankStateTrackers_1_io_tCycle),
    .io_cmdUsesThisRank(rankStateTrackers_1_io_cmdUsesThisRank),
    .io_cmdBankOH(rankStateTrackers_1_io_cmdBankOH),
    .targetFire(rankStateTrackers_1_targetFire)
  );
  RankStateTracker rankStateTrackers_2 (
    .clock(rankStateTrackers_2_clock),
    .reset(rankStateTrackers_2_reset),
    .io_timings_tAL(rankStateTrackers_2_io_timings_tAL),
    .io_timings_tCAS(rankStateTrackers_2_io_timings_tCAS),
    .io_timings_tCWD(rankStateTrackers_2_io_timings_tCWD),
    .io_timings_tCCD(rankStateTrackers_2_io_timings_tCCD),
    .io_timings_tFAW(rankStateTrackers_2_io_timings_tFAW),
    .io_timings_tRAS(rankStateTrackers_2_io_timings_tRAS),
    .io_timings_tREFI(rankStateTrackers_2_io_timings_tREFI),
    .io_timings_tRC(rankStateTrackers_2_io_timings_tRC),
    .io_timings_tRCD(rankStateTrackers_2_io_timings_tRCD),
    .io_timings_tRFC(rankStateTrackers_2_io_timings_tRFC),
    .io_timings_tRRD(rankStateTrackers_2_io_timings_tRRD),
    .io_timings_tRP(rankStateTrackers_2_io_timings_tRP),
    .io_timings_tRTP(rankStateTrackers_2_io_timings_tRTP),
    .io_timings_tRTRS(rankStateTrackers_2_io_timings_tRTRS),
    .io_timings_tWR(rankStateTrackers_2_io_timings_tWR),
    .io_timings_tWTR(rankStateTrackers_2_io_timings_tWTR),
    .io_selectedCmd(rankStateTrackers_2_io_selectedCmd),
    .io_autoPRE(rankStateTrackers_2_io_autoPRE),
    .io_cmdRow(rankStateTrackers_2_io_cmdRow),
    .io_rank_canCASW(rankStateTrackers_2_io_rank_canCASW),
    .io_rank_canCASR(rankStateTrackers_2_io_rank_canCASR),
    .io_rank_canPRE(rankStateTrackers_2_io_rank_canPRE),
    .io_rank_canACT(rankStateTrackers_2_io_rank_canACT),
    .io_rank_canREF(rankStateTrackers_2_io_rank_canREF),
    .io_rank_wantREF(rankStateTrackers_2_io_rank_wantREF),
    .io_rank_state(rankStateTrackers_2_io_rank_state),
    .io_rank_banks_0_canCASW(rankStateTrackers_2_io_rank_banks_0_canCASW),
    .io_rank_banks_0_canCASR(rankStateTrackers_2_io_rank_banks_0_canCASR),
    .io_rank_banks_0_canPRE(rankStateTrackers_2_io_rank_banks_0_canPRE),
    .io_rank_banks_0_canACT(rankStateTrackers_2_io_rank_banks_0_canACT),
    .io_rank_banks_0_openRow(rankStateTrackers_2_io_rank_banks_0_openRow),
    .io_rank_banks_0_state(rankStateTrackers_2_io_rank_banks_0_state),
    .io_rank_banks_1_canCASW(rankStateTrackers_2_io_rank_banks_1_canCASW),
    .io_rank_banks_1_canCASR(rankStateTrackers_2_io_rank_banks_1_canCASR),
    .io_rank_banks_1_canPRE(rankStateTrackers_2_io_rank_banks_1_canPRE),
    .io_rank_banks_1_canACT(rankStateTrackers_2_io_rank_banks_1_canACT),
    .io_rank_banks_1_openRow(rankStateTrackers_2_io_rank_banks_1_openRow),
    .io_rank_banks_1_state(rankStateTrackers_2_io_rank_banks_1_state),
    .io_rank_banks_2_canCASW(rankStateTrackers_2_io_rank_banks_2_canCASW),
    .io_rank_banks_2_canCASR(rankStateTrackers_2_io_rank_banks_2_canCASR),
    .io_rank_banks_2_canPRE(rankStateTrackers_2_io_rank_banks_2_canPRE),
    .io_rank_banks_2_canACT(rankStateTrackers_2_io_rank_banks_2_canACT),
    .io_rank_banks_2_openRow(rankStateTrackers_2_io_rank_banks_2_openRow),
    .io_rank_banks_2_state(rankStateTrackers_2_io_rank_banks_2_state),
    .io_rank_banks_3_canCASW(rankStateTrackers_2_io_rank_banks_3_canCASW),
    .io_rank_banks_3_canCASR(rankStateTrackers_2_io_rank_banks_3_canCASR),
    .io_rank_banks_3_canPRE(rankStateTrackers_2_io_rank_banks_3_canPRE),
    .io_rank_banks_3_canACT(rankStateTrackers_2_io_rank_banks_3_canACT),
    .io_rank_banks_3_openRow(rankStateTrackers_2_io_rank_banks_3_openRow),
    .io_rank_banks_3_state(rankStateTrackers_2_io_rank_banks_3_state),
    .io_rank_banks_4_canCASW(rankStateTrackers_2_io_rank_banks_4_canCASW),
    .io_rank_banks_4_canCASR(rankStateTrackers_2_io_rank_banks_4_canCASR),
    .io_rank_banks_4_canPRE(rankStateTrackers_2_io_rank_banks_4_canPRE),
    .io_rank_banks_4_canACT(rankStateTrackers_2_io_rank_banks_4_canACT),
    .io_rank_banks_4_openRow(rankStateTrackers_2_io_rank_banks_4_openRow),
    .io_rank_banks_4_state(rankStateTrackers_2_io_rank_banks_4_state),
    .io_rank_banks_5_canCASW(rankStateTrackers_2_io_rank_banks_5_canCASW),
    .io_rank_banks_5_canCASR(rankStateTrackers_2_io_rank_banks_5_canCASR),
    .io_rank_banks_5_canPRE(rankStateTrackers_2_io_rank_banks_5_canPRE),
    .io_rank_banks_5_canACT(rankStateTrackers_2_io_rank_banks_5_canACT),
    .io_rank_banks_5_openRow(rankStateTrackers_2_io_rank_banks_5_openRow),
    .io_rank_banks_5_state(rankStateTrackers_2_io_rank_banks_5_state),
    .io_rank_banks_6_canCASW(rankStateTrackers_2_io_rank_banks_6_canCASW),
    .io_rank_banks_6_canCASR(rankStateTrackers_2_io_rank_banks_6_canCASR),
    .io_rank_banks_6_canPRE(rankStateTrackers_2_io_rank_banks_6_canPRE),
    .io_rank_banks_6_canACT(rankStateTrackers_2_io_rank_banks_6_canACT),
    .io_rank_banks_6_openRow(rankStateTrackers_2_io_rank_banks_6_openRow),
    .io_rank_banks_6_state(rankStateTrackers_2_io_rank_banks_6_state),
    .io_rank_banks_7_canCASW(rankStateTrackers_2_io_rank_banks_7_canCASW),
    .io_rank_banks_7_canCASR(rankStateTrackers_2_io_rank_banks_7_canCASR),
    .io_rank_banks_7_canPRE(rankStateTrackers_2_io_rank_banks_7_canPRE),
    .io_rank_banks_7_canACT(rankStateTrackers_2_io_rank_banks_7_canACT),
    .io_rank_banks_7_openRow(rankStateTrackers_2_io_rank_banks_7_openRow),
    .io_rank_banks_7_state(rankStateTrackers_2_io_rank_banks_7_state),
    .io_tCycle(rankStateTrackers_2_io_tCycle),
    .io_cmdUsesThisRank(rankStateTrackers_2_io_cmdUsesThisRank),
    .io_cmdBankOH(rankStateTrackers_2_io_cmdBankOH),
    .targetFire(rankStateTrackers_2_targetFire)
  );
  RankStateTracker rankStateTrackers_3 (
    .clock(rankStateTrackers_3_clock),
    .reset(rankStateTrackers_3_reset),
    .io_timings_tAL(rankStateTrackers_3_io_timings_tAL),
    .io_timings_tCAS(rankStateTrackers_3_io_timings_tCAS),
    .io_timings_tCWD(rankStateTrackers_3_io_timings_tCWD),
    .io_timings_tCCD(rankStateTrackers_3_io_timings_tCCD),
    .io_timings_tFAW(rankStateTrackers_3_io_timings_tFAW),
    .io_timings_tRAS(rankStateTrackers_3_io_timings_tRAS),
    .io_timings_tREFI(rankStateTrackers_3_io_timings_tREFI),
    .io_timings_tRC(rankStateTrackers_3_io_timings_tRC),
    .io_timings_tRCD(rankStateTrackers_3_io_timings_tRCD),
    .io_timings_tRFC(rankStateTrackers_3_io_timings_tRFC),
    .io_timings_tRRD(rankStateTrackers_3_io_timings_tRRD),
    .io_timings_tRP(rankStateTrackers_3_io_timings_tRP),
    .io_timings_tRTP(rankStateTrackers_3_io_timings_tRTP),
    .io_timings_tRTRS(rankStateTrackers_3_io_timings_tRTRS),
    .io_timings_tWR(rankStateTrackers_3_io_timings_tWR),
    .io_timings_tWTR(rankStateTrackers_3_io_timings_tWTR),
    .io_selectedCmd(rankStateTrackers_3_io_selectedCmd),
    .io_autoPRE(rankStateTrackers_3_io_autoPRE),
    .io_cmdRow(rankStateTrackers_3_io_cmdRow),
    .io_rank_canCASW(rankStateTrackers_3_io_rank_canCASW),
    .io_rank_canCASR(rankStateTrackers_3_io_rank_canCASR),
    .io_rank_canPRE(rankStateTrackers_3_io_rank_canPRE),
    .io_rank_canACT(rankStateTrackers_3_io_rank_canACT),
    .io_rank_canREF(rankStateTrackers_3_io_rank_canREF),
    .io_rank_wantREF(rankStateTrackers_3_io_rank_wantREF),
    .io_rank_state(rankStateTrackers_3_io_rank_state),
    .io_rank_banks_0_canCASW(rankStateTrackers_3_io_rank_banks_0_canCASW),
    .io_rank_banks_0_canCASR(rankStateTrackers_3_io_rank_banks_0_canCASR),
    .io_rank_banks_0_canPRE(rankStateTrackers_3_io_rank_banks_0_canPRE),
    .io_rank_banks_0_canACT(rankStateTrackers_3_io_rank_banks_0_canACT),
    .io_rank_banks_0_openRow(rankStateTrackers_3_io_rank_banks_0_openRow),
    .io_rank_banks_0_state(rankStateTrackers_3_io_rank_banks_0_state),
    .io_rank_banks_1_canCASW(rankStateTrackers_3_io_rank_banks_1_canCASW),
    .io_rank_banks_1_canCASR(rankStateTrackers_3_io_rank_banks_1_canCASR),
    .io_rank_banks_1_canPRE(rankStateTrackers_3_io_rank_banks_1_canPRE),
    .io_rank_banks_1_canACT(rankStateTrackers_3_io_rank_banks_1_canACT),
    .io_rank_banks_1_openRow(rankStateTrackers_3_io_rank_banks_1_openRow),
    .io_rank_banks_1_state(rankStateTrackers_3_io_rank_banks_1_state),
    .io_rank_banks_2_canCASW(rankStateTrackers_3_io_rank_banks_2_canCASW),
    .io_rank_banks_2_canCASR(rankStateTrackers_3_io_rank_banks_2_canCASR),
    .io_rank_banks_2_canPRE(rankStateTrackers_3_io_rank_banks_2_canPRE),
    .io_rank_banks_2_canACT(rankStateTrackers_3_io_rank_banks_2_canACT),
    .io_rank_banks_2_openRow(rankStateTrackers_3_io_rank_banks_2_openRow),
    .io_rank_banks_2_state(rankStateTrackers_3_io_rank_banks_2_state),
    .io_rank_banks_3_canCASW(rankStateTrackers_3_io_rank_banks_3_canCASW),
    .io_rank_banks_3_canCASR(rankStateTrackers_3_io_rank_banks_3_canCASR),
    .io_rank_banks_3_canPRE(rankStateTrackers_3_io_rank_banks_3_canPRE),
    .io_rank_banks_3_canACT(rankStateTrackers_3_io_rank_banks_3_canACT),
    .io_rank_banks_3_openRow(rankStateTrackers_3_io_rank_banks_3_openRow),
    .io_rank_banks_3_state(rankStateTrackers_3_io_rank_banks_3_state),
    .io_rank_banks_4_canCASW(rankStateTrackers_3_io_rank_banks_4_canCASW),
    .io_rank_banks_4_canCASR(rankStateTrackers_3_io_rank_banks_4_canCASR),
    .io_rank_banks_4_canPRE(rankStateTrackers_3_io_rank_banks_4_canPRE),
    .io_rank_banks_4_canACT(rankStateTrackers_3_io_rank_banks_4_canACT),
    .io_rank_banks_4_openRow(rankStateTrackers_3_io_rank_banks_4_openRow),
    .io_rank_banks_4_state(rankStateTrackers_3_io_rank_banks_4_state),
    .io_rank_banks_5_canCASW(rankStateTrackers_3_io_rank_banks_5_canCASW),
    .io_rank_banks_5_canCASR(rankStateTrackers_3_io_rank_banks_5_canCASR),
    .io_rank_banks_5_canPRE(rankStateTrackers_3_io_rank_banks_5_canPRE),
    .io_rank_banks_5_canACT(rankStateTrackers_3_io_rank_banks_5_canACT),
    .io_rank_banks_5_openRow(rankStateTrackers_3_io_rank_banks_5_openRow),
    .io_rank_banks_5_state(rankStateTrackers_3_io_rank_banks_5_state),
    .io_rank_banks_6_canCASW(rankStateTrackers_3_io_rank_banks_6_canCASW),
    .io_rank_banks_6_canCASR(rankStateTrackers_3_io_rank_banks_6_canCASR),
    .io_rank_banks_6_canPRE(rankStateTrackers_3_io_rank_banks_6_canPRE),
    .io_rank_banks_6_canACT(rankStateTrackers_3_io_rank_banks_6_canACT),
    .io_rank_banks_6_openRow(rankStateTrackers_3_io_rank_banks_6_openRow),
    .io_rank_banks_6_state(rankStateTrackers_3_io_rank_banks_6_state),
    .io_rank_banks_7_canCASW(rankStateTrackers_3_io_rank_banks_7_canCASW),
    .io_rank_banks_7_canCASR(rankStateTrackers_3_io_rank_banks_7_canCASR),
    .io_rank_banks_7_canPRE(rankStateTrackers_3_io_rank_banks_7_canPRE),
    .io_rank_banks_7_canACT(rankStateTrackers_3_io_rank_banks_7_canACT),
    .io_rank_banks_7_openRow(rankStateTrackers_3_io_rank_banks_7_openRow),
    .io_rank_banks_7_state(rankStateTrackers_3_io_rank_banks_7_state),
    .io_tCycle(rankStateTrackers_3_io_tCycle),
    .io_cmdUsesThisRank(rankStateTrackers_3_io_cmdUsesThisRank),
    .io_cmdBankOH(rankStateTrackers_3_io_cmdBankOH),
    .targetFire(rankStateTrackers_3_targetFire)
  );
  RefreshUnit RefreshUnit (
    .io_rankStati_0_canPRE(RefreshUnit_io_rankStati_0_canPRE),
    .io_rankStati_0_canREF(RefreshUnit_io_rankStati_0_canREF),
    .io_rankStati_0_wantREF(RefreshUnit_io_rankStati_0_wantREF),
    .io_rankStati_0_banks_0_canPRE(RefreshUnit_io_rankStati_0_banks_0_canPRE),
    .io_rankStati_0_banks_1_canPRE(RefreshUnit_io_rankStati_0_banks_1_canPRE),
    .io_rankStati_0_banks_2_canPRE(RefreshUnit_io_rankStati_0_banks_2_canPRE),
    .io_rankStati_0_banks_3_canPRE(RefreshUnit_io_rankStati_0_banks_3_canPRE),
    .io_rankStati_0_banks_4_canPRE(RefreshUnit_io_rankStati_0_banks_4_canPRE),
    .io_rankStati_0_banks_5_canPRE(RefreshUnit_io_rankStati_0_banks_5_canPRE),
    .io_rankStati_0_banks_6_canPRE(RefreshUnit_io_rankStati_0_banks_6_canPRE),
    .io_rankStati_0_banks_7_canPRE(RefreshUnit_io_rankStati_0_banks_7_canPRE),
    .io_rankStati_1_canPRE(RefreshUnit_io_rankStati_1_canPRE),
    .io_rankStati_1_canREF(RefreshUnit_io_rankStati_1_canREF),
    .io_rankStati_1_wantREF(RefreshUnit_io_rankStati_1_wantREF),
    .io_rankStati_1_banks_0_canPRE(RefreshUnit_io_rankStati_1_banks_0_canPRE),
    .io_rankStati_1_banks_1_canPRE(RefreshUnit_io_rankStati_1_banks_1_canPRE),
    .io_rankStati_1_banks_2_canPRE(RefreshUnit_io_rankStati_1_banks_2_canPRE),
    .io_rankStati_1_banks_3_canPRE(RefreshUnit_io_rankStati_1_banks_3_canPRE),
    .io_rankStati_1_banks_4_canPRE(RefreshUnit_io_rankStati_1_banks_4_canPRE),
    .io_rankStati_1_banks_5_canPRE(RefreshUnit_io_rankStati_1_banks_5_canPRE),
    .io_rankStati_1_banks_6_canPRE(RefreshUnit_io_rankStati_1_banks_6_canPRE),
    .io_rankStati_1_banks_7_canPRE(RefreshUnit_io_rankStati_1_banks_7_canPRE),
    .io_rankStati_2_canPRE(RefreshUnit_io_rankStati_2_canPRE),
    .io_rankStati_2_canREF(RefreshUnit_io_rankStati_2_canREF),
    .io_rankStati_2_wantREF(RefreshUnit_io_rankStati_2_wantREF),
    .io_rankStati_2_banks_0_canPRE(RefreshUnit_io_rankStati_2_banks_0_canPRE),
    .io_rankStati_2_banks_1_canPRE(RefreshUnit_io_rankStati_2_banks_1_canPRE),
    .io_rankStati_2_banks_2_canPRE(RefreshUnit_io_rankStati_2_banks_2_canPRE),
    .io_rankStati_2_banks_3_canPRE(RefreshUnit_io_rankStati_2_banks_3_canPRE),
    .io_rankStati_2_banks_4_canPRE(RefreshUnit_io_rankStati_2_banks_4_canPRE),
    .io_rankStati_2_banks_5_canPRE(RefreshUnit_io_rankStati_2_banks_5_canPRE),
    .io_rankStati_2_banks_6_canPRE(RefreshUnit_io_rankStati_2_banks_6_canPRE),
    .io_rankStati_2_banks_7_canPRE(RefreshUnit_io_rankStati_2_banks_7_canPRE),
    .io_rankStati_3_canPRE(RefreshUnit_io_rankStati_3_canPRE),
    .io_rankStati_3_canREF(RefreshUnit_io_rankStati_3_canREF),
    .io_rankStati_3_wantREF(RefreshUnit_io_rankStati_3_wantREF),
    .io_rankStati_3_banks_0_canPRE(RefreshUnit_io_rankStati_3_banks_0_canPRE),
    .io_rankStati_3_banks_1_canPRE(RefreshUnit_io_rankStati_3_banks_1_canPRE),
    .io_rankStati_3_banks_2_canPRE(RefreshUnit_io_rankStati_3_banks_2_canPRE),
    .io_rankStati_3_banks_3_canPRE(RefreshUnit_io_rankStati_3_banks_3_canPRE),
    .io_rankStati_3_banks_4_canPRE(RefreshUnit_io_rankStati_3_banks_4_canPRE),
    .io_rankStati_3_banks_5_canPRE(RefreshUnit_io_rankStati_3_banks_5_canPRE),
    .io_rankStati_3_banks_6_canPRE(RefreshUnit_io_rankStati_3_banks_6_canPRE),
    .io_rankStati_3_banks_7_canPRE(RefreshUnit_io_rankStati_3_banks_7_canPRE),
    .io_ranksInUse(RefreshUnit_io_ranksInUse),
    .io_suggestREF(RefreshUnit_io_suggestREF),
    .io_refRankAddr(RefreshUnit_io_refRankAddr),
    .io_suggestPRE(RefreshUnit_io_suggestPRE),
    .io_preRankAddr(RefreshUnit_io_preRankAddr),
    .io_preBankAddr(RefreshUnit_io_preBankAddr)
  );
  CommandBusMonitor cmdMonitor (
    .clock(cmdMonitor_clock),
    .reset(cmdMonitor_reset),
    .io_cmd(cmdMonitor_io_cmd),
    .io_rank(cmdMonitor_io_rank),
    .io_bank(cmdMonitor_io_bank),
    .io_row(cmdMonitor_io_row),
    .io_autoPRE(cmdMonitor_io_autoPRE),
    .targetFire(cmdMonitor_targetFire)
  );
  RankPowerMonitor powerStats_powerMonitor (
    .clock(powerStats_powerMonitor_clock),
    .reset(powerStats_powerMonitor_reset),
    .io_stats_allPreCycles(powerStats_powerMonitor_io_stats_allPreCycles),
    .io_stats_numCASR(powerStats_powerMonitor_io_stats_numCASR),
    .io_stats_numCASW(powerStats_powerMonitor_io_stats_numCASW),
    .io_stats_numACT(powerStats_powerMonitor_io_stats_numACT),
    .io_rankState_state(powerStats_powerMonitor_io_rankState_state),
    .io_rankState_banks_0_canACT(powerStats_powerMonitor_io_rankState_banks_0_canACT),
    .io_rankState_banks_1_canACT(powerStats_powerMonitor_io_rankState_banks_1_canACT),
    .io_rankState_banks_2_canACT(powerStats_powerMonitor_io_rankState_banks_2_canACT),
    .io_rankState_banks_3_canACT(powerStats_powerMonitor_io_rankState_banks_3_canACT),
    .io_rankState_banks_4_canACT(powerStats_powerMonitor_io_rankState_banks_4_canACT),
    .io_rankState_banks_5_canACT(powerStats_powerMonitor_io_rankState_banks_5_canACT),
    .io_rankState_banks_6_canACT(powerStats_powerMonitor_io_rankState_banks_6_canACT),
    .io_rankState_banks_7_canACT(powerStats_powerMonitor_io_rankState_banks_7_canACT),
    .io_selectedCmd(powerStats_powerMonitor_io_selectedCmd),
    .io_cmdUsesThisRank(powerStats_powerMonitor_io_cmdUsesThisRank),
    .targetFire(powerStats_powerMonitor_targetFire)
  );
  RankPowerMonitor powerStats_powerMonitor_1 (
    .clock(powerStats_powerMonitor_1_clock),
    .reset(powerStats_powerMonitor_1_reset),
    .io_stats_allPreCycles(powerStats_powerMonitor_1_io_stats_allPreCycles),
    .io_stats_numCASR(powerStats_powerMonitor_1_io_stats_numCASR),
    .io_stats_numCASW(powerStats_powerMonitor_1_io_stats_numCASW),
    .io_stats_numACT(powerStats_powerMonitor_1_io_stats_numACT),
    .io_rankState_state(powerStats_powerMonitor_1_io_rankState_state),
    .io_rankState_banks_0_canACT(powerStats_powerMonitor_1_io_rankState_banks_0_canACT),
    .io_rankState_banks_1_canACT(powerStats_powerMonitor_1_io_rankState_banks_1_canACT),
    .io_rankState_banks_2_canACT(powerStats_powerMonitor_1_io_rankState_banks_2_canACT),
    .io_rankState_banks_3_canACT(powerStats_powerMonitor_1_io_rankState_banks_3_canACT),
    .io_rankState_banks_4_canACT(powerStats_powerMonitor_1_io_rankState_banks_4_canACT),
    .io_rankState_banks_5_canACT(powerStats_powerMonitor_1_io_rankState_banks_5_canACT),
    .io_rankState_banks_6_canACT(powerStats_powerMonitor_1_io_rankState_banks_6_canACT),
    .io_rankState_banks_7_canACT(powerStats_powerMonitor_1_io_rankState_banks_7_canACT),
    .io_selectedCmd(powerStats_powerMonitor_1_io_selectedCmd),
    .io_cmdUsesThisRank(powerStats_powerMonitor_1_io_cmdUsesThisRank),
    .targetFire(powerStats_powerMonitor_1_targetFire)
  );
  RankPowerMonitor powerStats_powerMonitor_2 (
    .clock(powerStats_powerMonitor_2_clock),
    .reset(powerStats_powerMonitor_2_reset),
    .io_stats_allPreCycles(powerStats_powerMonitor_2_io_stats_allPreCycles),
    .io_stats_numCASR(powerStats_powerMonitor_2_io_stats_numCASR),
    .io_stats_numCASW(powerStats_powerMonitor_2_io_stats_numCASW),
    .io_stats_numACT(powerStats_powerMonitor_2_io_stats_numACT),
    .io_rankState_state(powerStats_powerMonitor_2_io_rankState_state),
    .io_rankState_banks_0_canACT(powerStats_powerMonitor_2_io_rankState_banks_0_canACT),
    .io_rankState_banks_1_canACT(powerStats_powerMonitor_2_io_rankState_banks_1_canACT),
    .io_rankState_banks_2_canACT(powerStats_powerMonitor_2_io_rankState_banks_2_canACT),
    .io_rankState_banks_3_canACT(powerStats_powerMonitor_2_io_rankState_banks_3_canACT),
    .io_rankState_banks_4_canACT(powerStats_powerMonitor_2_io_rankState_banks_4_canACT),
    .io_rankState_banks_5_canACT(powerStats_powerMonitor_2_io_rankState_banks_5_canACT),
    .io_rankState_banks_6_canACT(powerStats_powerMonitor_2_io_rankState_banks_6_canACT),
    .io_rankState_banks_7_canACT(powerStats_powerMonitor_2_io_rankState_banks_7_canACT),
    .io_selectedCmd(powerStats_powerMonitor_2_io_selectedCmd),
    .io_cmdUsesThisRank(powerStats_powerMonitor_2_io_cmdUsesThisRank),
    .targetFire(powerStats_powerMonitor_2_targetFire)
  );
  RankPowerMonitor powerStats_powerMonitor_3 (
    .clock(powerStats_powerMonitor_3_clock),
    .reset(powerStats_powerMonitor_3_reset),
    .io_stats_allPreCycles(powerStats_powerMonitor_3_io_stats_allPreCycles),
    .io_stats_numCASR(powerStats_powerMonitor_3_io_stats_numCASR),
    .io_stats_numCASW(powerStats_powerMonitor_3_io_stats_numCASW),
    .io_stats_numACT(powerStats_powerMonitor_3_io_stats_numACT),
    .io_rankState_state(powerStats_powerMonitor_3_io_rankState_state),
    .io_rankState_banks_0_canACT(powerStats_powerMonitor_3_io_rankState_banks_0_canACT),
    .io_rankState_banks_1_canACT(powerStats_powerMonitor_3_io_rankState_banks_1_canACT),
    .io_rankState_banks_2_canACT(powerStats_powerMonitor_3_io_rankState_banks_2_canACT),
    .io_rankState_banks_3_canACT(powerStats_powerMonitor_3_io_rankState_banks_3_canACT),
    .io_rankState_banks_4_canACT(powerStats_powerMonitor_3_io_rankState_banks_4_canACT),
    .io_rankState_banks_5_canACT(powerStats_powerMonitor_3_io_rankState_banks_5_canACT),
    .io_rankState_banks_6_canACT(powerStats_powerMonitor_3_io_rankState_banks_6_canACT),
    .io_rankState_banks_7_canACT(powerStats_powerMonitor_3_io_rankState_banks_7_canACT),
    .io_selectedCmd(powerStats_powerMonitor_3_io_selectedCmd),
    .io_cmdUsesThisRank(powerStats_powerMonitor_3_io_cmdUsesThisRank),
    .targetFire(powerStats_powerMonitor_3_targetFire)
  );
  assign io_tNasti_aw_ready = nastiReqIden_io_in_aw_ready; // @[Interfaces.scala 17:8]
  assign io_tNasti_w_ready = nastiReqIden_io_in_w_ready; // @[Interfaces.scala 19:8]
  assign io_tNasti_b_valid = xactionRelease_io_b_valid; // @[TimingModel.scala 122:12]
  assign io_tNasti_b_bits_id = xactionRelease_io_b_bits_id; // @[TimingModel.scala 122:12]
  assign io_tNasti_ar_ready = nastiReqIden_io_in_ar_ready; // @[Interfaces.scala 18:8]
  assign io_tNasti_r_valid = xactionRelease_io_r_valid; // @[TimingModel.scala 123:12]
  assign io_tNasti_r_bits_data = xactionRelease_io_r_bits_data; // @[TimingModel.scala 123:12]
  assign io_tNasti_r_bits_last = xactionRelease_io_r_bits_last; // @[TimingModel.scala 123:12]
  assign io_tNasti_r_bits_id = xactionRelease_io_r_bits_id; // @[TimingModel.scala 123:12]
  assign io_egressReq_b_valid = xactionRelease_io_egressReq_b_valid; // @[TimingModel.scala 124:16]
  assign io_egressReq_b_bits = xactionRelease_io_egressReq_b_bits; // @[TimingModel.scala 124:16]
  assign io_egressReq_r_valid = xactionRelease_io_egressReq_r_valid; // @[TimingModel.scala 124:16]
  assign io_egressReq_r_bits = xactionRelease_io_egressReq_r_bits; // @[TimingModel.scala 124:16]
  assign io_egressResp_bReady = xactionRelease_io_egressResp_bReady; // @[TimingModel.scala 125:32]
  assign io_egressResp_rReady = xactionRelease_io_egressResp_rReady; // @[TimingModel.scala 125:32]
  assign io_mmReg_totalReads = totalReads; // @[TimingModel.scala 149:37]
  assign io_mmReg_totalWrites = totalWrites; // @[TimingModel.scala 150:38]
  assign io_mmReg_totalReadBeats = totalReadBeats; // @[TimingModel.scala 158:41]
  assign io_mmReg_totalWriteBeats = totalWriteBeats; // @[TimingModel.scala 159:42]
  assign io_mmReg_readOutstandingHistogram_0 = readOutstandingHistogram_0; // @[TimingModel.scala 182:41]
  assign io_mmReg_readOutstandingHistogram_1 = readOutstandingHistogram_1; // @[TimingModel.scala 182:41]
  assign io_mmReg_readOutstandingHistogram_2 = readOutstandingHistogram_2; // @[TimingModel.scala 182:41]
  assign io_mmReg_readOutstandingHistogram_3 = readOutstandingHistogram_3; // @[TimingModel.scala 182:41]
  assign io_mmReg_writeOutstandingHistogram_0 = writeOutstandingHistogram_0; // @[TimingModel.scala 183:42]
  assign io_mmReg_writeOutstandingHistogram_1 = writeOutstandingHistogram_1; // @[TimingModel.scala 183:42]
  assign io_mmReg_writeOutstandingHistogram_2 = writeOutstandingHistogram_2; // @[TimingModel.scala 183:42]
  assign io_mmReg_writeOutstandingHistogram_3 = writeOutstandingHistogram_3; // @[TimingModel.scala 183:42]
  assign io_mmReg_rankPower_0_allPreCycles = powerStats_powerMonitor_io_stats_allPreCycles; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_0_numCASR = powerStats_powerMonitor_io_stats_numCASR; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_0_numCASW = powerStats_powerMonitor_io_stats_numCASW; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_0_numACT = powerStats_powerMonitor_io_stats_numACT; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_1_allPreCycles = powerStats_powerMonitor_1_io_stats_allPreCycles; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_1_numCASR = powerStats_powerMonitor_1_io_stats_numCASR; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_1_numCASW = powerStats_powerMonitor_1_io_stats_numCASW; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_1_numACT = powerStats_powerMonitor_1_io_stats_numACT; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_2_allPreCycles = powerStats_powerMonitor_2_io_stats_allPreCycles; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_2_numCASR = powerStats_powerMonitor_2_io_stats_numCASR; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_2_numCASW = powerStats_powerMonitor_2_io_stats_numCASW; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_2_numACT = powerStats_powerMonitor_2_io_stats_numACT; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_3_allPreCycles = powerStats_powerMonitor_3_io_stats_allPreCycles; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_3_numCASR = powerStats_powerMonitor_3_io_stats_numCASR; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_3_numCASW = powerStats_powerMonitor_3_io_stats_numCASW; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign io_mmReg_rankPower_3_numACT = powerStats_powerMonitor_3_io_stats_numACT; // @[FIFOMASModel.scala 171:32 FIFOMASModel.scala 171:32]
  assign nastiReqIden_io_in_aw_valid = io_tNasti_aw_valid; // @[Interfaces.scala 17:8]
  assign nastiReqIden_io_in_aw_bits_addr = io_tNasti_aw_bits_addr; // @[Interfaces.scala 17:8]
  assign nastiReqIden_io_in_aw_bits_id = io_tNasti_aw_bits_id; // @[Interfaces.scala 17:8]
  assign nastiReqIden_io_in_w_valid = io_tNasti_w_valid; // @[Interfaces.scala 19:8]
  assign nastiReqIden_io_in_w_bits_last = io_tNasti_w_bits_last; // @[Interfaces.scala 19:8]
  assign nastiReqIden_io_in_ar_valid = io_tNasti_ar_valid; // @[Interfaces.scala 18:8]
  assign nastiReqIden_io_in_ar_bits_addr = io_tNasti_ar_bits_addr; // @[Interfaces.scala 18:8]
  assign nastiReqIden_io_in_ar_bits_id = io_tNasti_ar_bits_id; // @[Interfaces.scala 18:8]
  assign nastiReqIden_io_out_aw_ready = xactionScheduler_io_req_aw_ready; // @[FIFOMASModel.scala 49:27]
  assign nastiReqIden_io_out_w_ready = xactionScheduler_io_req_w_ready; // @[FIFOMASModel.scala 49:27]
  assign nastiReqIden_io_out_ar_ready = xactionScheduler_io_req_ar_ready; // @[FIFOMASModel.scala 49:27]
  assign monitor_clock = clock;
  assign monitor_reset = reset;
  assign monitor_axi4_aw_ready = io_tNasti_aw_ready; // @[TimingModel.scala 95:16]
  assign monitor_axi4_aw_valid = io_tNasti_aw_valid; // @[TimingModel.scala 95:16]
  assign monitor_axi4_aw_bits_len = io_tNasti_aw_bits_len; // @[TimingModel.scala 95:16]
  assign monitor_axi4_ar_ready = io_tNasti_ar_ready; // @[TimingModel.scala 95:16]
  assign monitor_axi4_ar_valid = io_tNasti_ar_valid; // @[TimingModel.scala 95:16]
  assign monitor_axi4_ar_bits_len = io_tNasti_ar_bits_len; // @[TimingModel.scala 95:16]
  assign monitor_targetFire = targetFire;
  assign SatUpDownCounter_clock = clock;
  assign SatUpDownCounter_reset = reset;
  assign SatUpDownCounter_io_inc = io_tNasti_ar_ready & io_tNasti_ar_valid; // @[Decoupled.scala 40:37]
  assign SatUpDownCounter_io_dec = _T_1 & io_tNasti_r_bits_last; // @[TimingModel.scala 104:39]
  assign SatUpDownCounter_targetFire = targetFire;
  assign SatUpDownCounter_1_clock = clock;
  assign SatUpDownCounter_1_reset = reset;
  assign SatUpDownCounter_1_io_inc = io_tNasti_aw_ready & io_tNasti_aw_valid; // @[Decoupled.scala 40:37]
  assign SatUpDownCounter_1_io_dec = io_tNasti_b_ready & io_tNasti_b_valid; // @[Decoupled.scala 40:37]
  assign SatUpDownCounter_1_targetFire = targetFire;
  assign SatUpDownCounter_2_clock = clock;
  assign SatUpDownCounter_2_reset = reset;
  assign SatUpDownCounter_2_io_inc = _T_5 & io_tNasti_w_bits_last; // @[TimingModel.scala 111:38]
  assign SatUpDownCounter_2_io_dec = io_tNasti_b_ready & io_tNasti_b_valid; // @[Decoupled.scala 40:37]
  assign SatUpDownCounter_2_targetFire = targetFire;
  assign xactionRelease_clock = clock;
  assign xactionRelease_reset = reset;
  assign xactionRelease_io_b_ready = io_tNasti_b_ready; // @[TimingModel.scala 122:12]
  assign xactionRelease_io_r_ready = io_tNasti_r_ready; // @[TimingModel.scala 123:12]
  assign xactionRelease_io_egressResp_bBits_id = io_egressResp_bBits_id; // @[TimingModel.scala 125:32]
  assign xactionRelease_io_egressResp_rBits_data = io_egressResp_rBits_data; // @[TimingModel.scala 125:32]
  assign xactionRelease_io_egressResp_rBits_last = io_egressResp_rBits_last; // @[TimingModel.scala 125:32]
  assign xactionRelease_io_egressResp_rBits_id = io_egressResp_rBits_id; // @[TimingModel.scala 125:32]
  assign xactionRelease_io_nextRead_valid = backend_io_completedRead_valid; // @[TimingModel.scala 92:19 FIFOMASModel.scala 152:9]
  assign xactionRelease_io_nextRead_bits_id = backend_io_completedRead_bits_id; // @[TimingModel.scala 92:19 FIFOMASModel.scala 152:9]
  assign xactionRelease_io_nextWrite_valid = backend_io_completedWrite_valid; // @[TimingModel.scala 91:19 FIFOMASModel.scala 151:9]
  assign xactionRelease_io_nextWrite_bits_id = backend_io_completedWrite_bits_id; // @[TimingModel.scala 91:19 FIFOMASModel.scala 151:9]
  assign xactionRelease_targetFire = targetFire;
  assign backend_clock = clock;
  assign backend_reset = reset;
  assign backend_io_newRead_valid = memReqDone & _canCASR_T_2; // @[FIFOMASModel.scala 143:42]
  assign backend_io_newRead_bits_id = currentReference_io_deq_bits_xaction_id; // @[Util.scala 294:28 Util.scala 295:21]
  assign backend_io_newWrite_valid = memReqDone & currentReference_io_deq_bits_xaction_isWrite; // @[FIFOMASModel.scala 148:43]
  assign backend_io_newWrite_bits_id = currentReference_io_deq_bits_xaction_id; // @[Util.scala 310:29 Util.scala 311:22]
  assign backend_io_completedRead_ready = xactionRelease_io_nextRead_ready; // @[TimingModel.scala 92:19 TimingModel.scala 140:32]
  assign backend_io_completedWrite_ready = xactionRelease_io_nextWrite_ready; // @[TimingModel.scala 91:19 TimingModel.scala 139:33]
  assign backend_io_readLatency = _GEN_485 + io_mmReg_backendLatency; // @[FIFOMASModel.scala 144:56]
  assign backend_io_tCycle = tCycle[11:0]; // @[FIFOMASModel.scala 141:21]
  assign backend_targetFire = targetFire;
  assign xactionScheduler_clock = clock;
  assign xactionScheduler_reset = reset;
  assign xactionScheduler_io_req_aw_valid = nastiReqIden_io_out_aw_valid; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_req_aw_bits_addr = nastiReqIden_io_out_aw_bits_addr; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_req_aw_bits_id = nastiReqIden_io_out_aw_bits_id; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_req_w_valid = nastiReqIden_io_out_w_valid; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_req_w_bits_last = nastiReqIden_io_out_w_bits_last; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_req_ar_valid = nastiReqIden_io_out_ar_valid; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_req_ar_bits_addr = nastiReqIden_io_out_ar_bits_addr; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_req_ar_bits_id = nastiReqIden_io_out_ar_bits_id; // @[FIFOMASModel.scala 49:27]
  assign xactionScheduler_io_nextXaction_ready = currentReference_io_enq_ready; // @[FIFOMASModel.scala 54:23 Decoupled.scala 299:17]
  assign xactionScheduler_io_pendingWReq = {{7'd0}, SatUpDownCounter_2_io_value}; // @[FIFOMASModel.scala 51:35]
  assign xactionScheduler_io_pendingAWReq = {{7'd0}, SatUpDownCounter_1_io_value}; // @[FIFOMASModel.scala 50:36]
  assign xactionScheduler_targetFire = targetFire;
  assign currentReference_clock = clock;
  assign currentReference_reset = reset;
  assign currentReference_io_enq_valid = xactionScheduler_io_nextXaction_valid; // @[FIFOMASModel.scala 54:23 FIFOMASModel.scala 55:18]
  assign currentReference_io_enq_bits_xaction_id = xactionScheduler_io_nextXaction_bits_xaction_id; // @[FIFOMASModel.scala 54:23 DramCommon.scala 316:13]
  assign currentReference_io_enq_bits_xaction_isWrite = xactionScheduler_io_nextXaction_bits_xaction_isWrite; // @[FIFOMASModel.scala 54:23 DramCommon.scala 316:13]
  assign currentReference_io_enq_bits_rowAddr = _currentReference_next_bits_rowAddr_T_1[25:0]; // @[FIFOMASModel.scala 54:23 DramCommon.scala 319:13]
  assign currentReference_io_enq_bits_bankAddr = _currentReference_next_bits_bankAddr_T_1[2:0]; // @[FIFOMASModel.scala 54:23 DramCommon.scala 317:14]
  assign currentReference_io_enq_bits_rankAddr = _currentReference_next_bits_rankAddr_T_1[1:0]; // @[FIFOMASModel.scala 54:23 DramCommon.scala 320:14]
  assign currentReference_io_deq_ready = selectedCmd == 3'h4 | selectedCmd == 3'h3; // @[FIFOMASModel.scala 62:46]
  assign currentReference_targetFire = targetFire;
  assign cmdBusBusy_clock = clock;
  assign cmdBusBusy_reset = reset;
  assign cmdBusBusy_io_set_valid = selectedCmd != 3'h0; // @[FIFOMASModel.scala 137:43]
  assign cmdBusBusy_io_set_bits = io_mmReg_dramTimings_tCMD - 7'h1; // @[FIFOMASModel.scala 136:42]
  assign cmdBusBusy_targetFire = targetFire;
  assign rankStateTrackers_0_clock = clock;
  assign rankStateTrackers_0_reset = reset;
  assign rankStateTrackers_0_io_timings_tAL = io_mmReg_dramTimings_tAL; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tCAS = io_mmReg_dramTimings_tCAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tCWD = io_mmReg_dramTimings_tCWD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tCCD = io_mmReg_dramTimings_tCCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tFAW = io_mmReg_dramTimings_tFAW; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRAS = io_mmReg_dramTimings_tRAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tREFI = io_mmReg_dramTimings_tREFI; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRC = io_mmReg_dramTimings_tRC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRCD = io_mmReg_dramTimings_tRCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRFC = io_mmReg_dramTimings_tRFC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRRD = io_mmReg_dramTimings_tRRD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRP = io_mmReg_dramTimings_tRP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRTP = io_mmReg_dramTimings_tRTP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tRTRS = io_mmReg_dramTimings_tRTRS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tWR = io_mmReg_dramTimings_tWR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_timings_tWTR = io_mmReg_dramTimings_tWTR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_0_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign rankStateTrackers_0_io_autoPRE = RefreshUnit_io_suggestREF ? 1'h0 : _GEN_462; // @[FIFOMASModel.scala 95:33]
  assign rankStateTrackers_0_io_cmdRow = currentReference_io_deq_bits_rowAddr; // @[FIFOMASModel.scala 127:21]
  assign rankStateTrackers_0_io_tCycle = tCycle[6:0]; // @[FIFOMASModel.scala 131:21]
  assign rankStateTrackers_0_io_cmdUsesThisRank = _T_78[0]; // @[FIFOMASModel.scala 124:43]
  assign rankStateTrackers_0_io_cmdBankOH = 8'h1 << cmdBank; // @[OneHot.scala 58:35]
  assign rankStateTrackers_0_targetFire = targetFire;
  assign rankStateTrackers_1_clock = clock;
  assign rankStateTrackers_1_reset = reset;
  assign rankStateTrackers_1_io_timings_tAL = io_mmReg_dramTimings_tAL; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tCAS = io_mmReg_dramTimings_tCAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tCWD = io_mmReg_dramTimings_tCWD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tCCD = io_mmReg_dramTimings_tCCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tFAW = io_mmReg_dramTimings_tFAW; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRAS = io_mmReg_dramTimings_tRAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tREFI = io_mmReg_dramTimings_tREFI; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRC = io_mmReg_dramTimings_tRC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRCD = io_mmReg_dramTimings_tRCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRFC = io_mmReg_dramTimings_tRFC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRRD = io_mmReg_dramTimings_tRRD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRP = io_mmReg_dramTimings_tRP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRTP = io_mmReg_dramTimings_tRTP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tRTRS = io_mmReg_dramTimings_tRTRS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tWR = io_mmReg_dramTimings_tWR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_timings_tWTR = io_mmReg_dramTimings_tWTR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_1_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign rankStateTrackers_1_io_autoPRE = RefreshUnit_io_suggestREF ? 1'h0 : _GEN_462; // @[FIFOMASModel.scala 95:33]
  assign rankStateTrackers_1_io_cmdRow = currentReference_io_deq_bits_rowAddr; // @[FIFOMASModel.scala 127:21]
  assign rankStateTrackers_1_io_tCycle = tCycle[6:0]; // @[FIFOMASModel.scala 131:21]
  assign rankStateTrackers_1_io_cmdUsesThisRank = _T_78[1]; // @[FIFOMASModel.scala 124:43]
  assign rankStateTrackers_1_io_cmdBankOH = 8'h1 << cmdBank; // @[OneHot.scala 58:35]
  assign rankStateTrackers_1_targetFire = targetFire;
  assign rankStateTrackers_2_clock = clock;
  assign rankStateTrackers_2_reset = reset;
  assign rankStateTrackers_2_io_timings_tAL = io_mmReg_dramTimings_tAL; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tCAS = io_mmReg_dramTimings_tCAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tCWD = io_mmReg_dramTimings_tCWD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tCCD = io_mmReg_dramTimings_tCCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tFAW = io_mmReg_dramTimings_tFAW; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRAS = io_mmReg_dramTimings_tRAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tREFI = io_mmReg_dramTimings_tREFI; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRC = io_mmReg_dramTimings_tRC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRCD = io_mmReg_dramTimings_tRCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRFC = io_mmReg_dramTimings_tRFC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRRD = io_mmReg_dramTimings_tRRD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRP = io_mmReg_dramTimings_tRP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRTP = io_mmReg_dramTimings_tRTP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tRTRS = io_mmReg_dramTimings_tRTRS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tWR = io_mmReg_dramTimings_tWR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_timings_tWTR = io_mmReg_dramTimings_tWTR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_2_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign rankStateTrackers_2_io_autoPRE = RefreshUnit_io_suggestREF ? 1'h0 : _GEN_462; // @[FIFOMASModel.scala 95:33]
  assign rankStateTrackers_2_io_cmdRow = currentReference_io_deq_bits_rowAddr; // @[FIFOMASModel.scala 127:21]
  assign rankStateTrackers_2_io_tCycle = tCycle[6:0]; // @[FIFOMASModel.scala 131:21]
  assign rankStateTrackers_2_io_cmdUsesThisRank = _T_78[2]; // @[FIFOMASModel.scala 124:43]
  assign rankStateTrackers_2_io_cmdBankOH = 8'h1 << cmdBank; // @[OneHot.scala 58:35]
  assign rankStateTrackers_2_targetFire = targetFire;
  assign rankStateTrackers_3_clock = clock;
  assign rankStateTrackers_3_reset = reset;
  assign rankStateTrackers_3_io_timings_tAL = io_mmReg_dramTimings_tAL; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tCAS = io_mmReg_dramTimings_tCAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tCWD = io_mmReg_dramTimings_tCWD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tCCD = io_mmReg_dramTimings_tCCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tFAW = io_mmReg_dramTimings_tFAW; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRAS = io_mmReg_dramTimings_tRAS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tREFI = io_mmReg_dramTimings_tREFI; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRC = io_mmReg_dramTimings_tRC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRCD = io_mmReg_dramTimings_tRCD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRFC = io_mmReg_dramTimings_tRFC; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRRD = io_mmReg_dramTimings_tRRD; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRP = io_mmReg_dramTimings_tRP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRTP = io_mmReg_dramTimings_tRTP; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tRTRS = io_mmReg_dramTimings_tRTRS; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tWR = io_mmReg_dramTimings_tWR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_timings_tWTR = io_mmReg_dramTimings_tWTR; // @[FIFOMASModel.scala 130:22]
  assign rankStateTrackers_3_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign rankStateTrackers_3_io_autoPRE = RefreshUnit_io_suggestREF ? 1'h0 : _GEN_462; // @[FIFOMASModel.scala 95:33]
  assign rankStateTrackers_3_io_cmdRow = currentReference_io_deq_bits_rowAddr; // @[FIFOMASModel.scala 127:21]
  assign rankStateTrackers_3_io_tCycle = tCycle[6:0]; // @[FIFOMASModel.scala 131:21]
  assign rankStateTrackers_3_io_cmdUsesThisRank = _T_78[3]; // @[FIFOMASModel.scala 124:43]
  assign rankStateTrackers_3_io_cmdBankOH = 8'h1 << cmdBank; // @[OneHot.scala 58:35]
  assign rankStateTrackers_3_targetFire = targetFire;
  assign RefreshUnit_io_rankStati_0_canPRE = rankStateTrackers_0_io_rank_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_canREF = rankStateTrackers_0_io_rank_canREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_wantREF = rankStateTrackers_0_io_rank_wantREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_0_canPRE = rankStateTrackers_0_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_1_canPRE = rankStateTrackers_0_io_rank_banks_1_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_2_canPRE = rankStateTrackers_0_io_rank_banks_2_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_3_canPRE = rankStateTrackers_0_io_rank_banks_3_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_4_canPRE = rankStateTrackers_0_io_rank_banks_4_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_5_canPRE = rankStateTrackers_0_io_rank_banks_5_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_6_canPRE = rankStateTrackers_0_io_rank_banks_6_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_0_banks_7_canPRE = rankStateTrackers_0_io_rank_banks_7_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_canPRE = rankStateTrackers_1_io_rank_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_canREF = rankStateTrackers_1_io_rank_canREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_wantREF = rankStateTrackers_1_io_rank_wantREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_0_canPRE = rankStateTrackers_1_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_1_canPRE = rankStateTrackers_1_io_rank_banks_1_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_2_canPRE = rankStateTrackers_1_io_rank_banks_2_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_3_canPRE = rankStateTrackers_1_io_rank_banks_3_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_4_canPRE = rankStateTrackers_1_io_rank_banks_4_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_5_canPRE = rankStateTrackers_1_io_rank_banks_5_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_6_canPRE = rankStateTrackers_1_io_rank_banks_6_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_1_banks_7_canPRE = rankStateTrackers_1_io_rank_banks_7_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_canPRE = rankStateTrackers_2_io_rank_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_canREF = rankStateTrackers_2_io_rank_canREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_wantREF = rankStateTrackers_2_io_rank_wantREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_0_canPRE = rankStateTrackers_2_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_1_canPRE = rankStateTrackers_2_io_rank_banks_1_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_2_canPRE = rankStateTrackers_2_io_rank_banks_2_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_3_canPRE = rankStateTrackers_2_io_rank_banks_3_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_4_canPRE = rankStateTrackers_2_io_rank_banks_4_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_5_canPRE = rankStateTrackers_2_io_rank_banks_5_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_6_canPRE = rankStateTrackers_2_io_rank_banks_6_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_2_banks_7_canPRE = rankStateTrackers_2_io_rank_banks_7_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_canPRE = rankStateTrackers_3_io_rank_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_canREF = rankStateTrackers_3_io_rank_canREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_wantREF = rankStateTrackers_3_io_rank_wantREF; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_0_canPRE = rankStateTrackers_3_io_rank_banks_0_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_1_canPRE = rankStateTrackers_3_io_rank_banks_1_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_2_canPRE = rankStateTrackers_3_io_rank_banks_2_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_3_canPRE = rankStateTrackers_3_io_rank_banks_3_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_4_canPRE = rankStateTrackers_3_io_rank_banks_4_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_5_canPRE = rankStateTrackers_3_io_rank_banks_5_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_6_canPRE = rankStateTrackers_3_io_rank_banks_6_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_rankStati_3_banks_7_canPRE = rankStateTrackers_3_io_rank_banks_7_canPRE; // @[FIFOMASModel.scala 93:14]
  assign RefreshUnit_io_ranksInUse = io_mmReg_rankAddr_mask[1] ? 4'hf : {{2'd0}, _T_64}; // @[Mux.scala 98:16]
  assign cmdMonitor_clock = clock;
  assign cmdMonitor_reset = reset;
  assign cmdMonitor_io_cmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign cmdMonitor_io_rank = RefreshUnit_io_suggestREF ? RefreshUnit_io_refRankAddr : _GEN_460; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 97:13]
  assign cmdMonitor_io_bank = RefreshUnit_io_suggestREF ? currentReference_io_deq_bits_bankAddr : _GEN_461; // @[FIFOMASModel.scala 95:33]
  assign cmdMonitor_io_row = currentReference_io_deq_bits_rowAddr; // @[FIFOMASModel.scala 159:21]
  assign cmdMonitor_io_autoPRE = RefreshUnit_io_suggestREF ? 1'h0 : _GEN_462; // @[FIFOMASModel.scala 95:33]
  assign cmdMonitor_targetFire = targetFire;
  assign powerStats_powerMonitor_clock = clock;
  assign powerStats_powerMonitor_reset = reset;
  assign powerStats_powerMonitor_io_rankState_state = rankStateTrackers_0_io_rank_state; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_0_canACT = rankStateTrackers_0_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_1_canACT = rankStateTrackers_0_io_rank_banks_1_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_2_canACT = rankStateTrackers_0_io_rank_banks_2_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_3_canACT = rankStateTrackers_0_io_rank_banks_3_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_4_canACT = rankStateTrackers_0_io_rank_banks_4_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_5_canACT = rankStateTrackers_0_io_rank_banks_5_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_6_canACT = rankStateTrackers_0_io_rank_banks_6_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_rankState_banks_7_canACT = rankStateTrackers_0_io_rank_banks_7_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign powerStats_powerMonitor_io_cmdUsesThisRank = _T_78[0]; // @[FIFOMASModel.scala 162:62]
  assign powerStats_powerMonitor_targetFire = targetFire;
  assign powerStats_powerMonitor_1_clock = clock;
  assign powerStats_powerMonitor_1_reset = reset;
  assign powerStats_powerMonitor_1_io_rankState_state = rankStateTrackers_1_io_rank_state; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_0_canACT = rankStateTrackers_1_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_1_canACT = rankStateTrackers_1_io_rank_banks_1_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_2_canACT = rankStateTrackers_1_io_rank_banks_2_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_3_canACT = rankStateTrackers_1_io_rank_banks_3_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_4_canACT = rankStateTrackers_1_io_rank_banks_4_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_5_canACT = rankStateTrackers_1_io_rank_banks_5_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_6_canACT = rankStateTrackers_1_io_rank_banks_6_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_rankState_banks_7_canACT = rankStateTrackers_1_io_rank_banks_7_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_1_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign powerStats_powerMonitor_1_io_cmdUsesThisRank = _T_78[1]; // @[FIFOMASModel.scala 162:62]
  assign powerStats_powerMonitor_1_targetFire = targetFire;
  assign powerStats_powerMonitor_2_clock = clock;
  assign powerStats_powerMonitor_2_reset = reset;
  assign powerStats_powerMonitor_2_io_rankState_state = rankStateTrackers_2_io_rank_state; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_0_canACT = rankStateTrackers_2_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_1_canACT = rankStateTrackers_2_io_rank_banks_1_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_2_canACT = rankStateTrackers_2_io_rank_banks_2_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_3_canACT = rankStateTrackers_2_io_rank_banks_3_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_4_canACT = rankStateTrackers_2_io_rank_banks_4_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_5_canACT = rankStateTrackers_2_io_rank_banks_5_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_6_canACT = rankStateTrackers_2_io_rank_banks_6_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_rankState_banks_7_canACT = rankStateTrackers_2_io_rank_banks_7_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_2_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign powerStats_powerMonitor_2_io_cmdUsesThisRank = _T_78[2]; // @[FIFOMASModel.scala 162:62]
  assign powerStats_powerMonitor_2_targetFire = targetFire;
  assign powerStats_powerMonitor_3_clock = clock;
  assign powerStats_powerMonitor_3_reset = reset;
  assign powerStats_powerMonitor_3_io_rankState_state = rankStateTrackers_3_io_rank_state; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_0_canACT = rankStateTrackers_3_io_rank_banks_0_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_1_canACT = rankStateTrackers_3_io_rank_banks_1_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_2_canACT = rankStateTrackers_3_io_rank_banks_2_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_3_canACT = rankStateTrackers_3_io_rank_banks_3_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_4_canACT = rankStateTrackers_3_io_rank_banks_4_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_5_canACT = rankStateTrackers_3_io_rank_banks_5_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_6_canACT = rankStateTrackers_3_io_rank_banks_6_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_rankState_banks_7_canACT = rankStateTrackers_3_io_rank_banks_7_canACT; // @[FIFOMASModel.scala 167:33]
  assign powerStats_powerMonitor_3_io_selectedCmd = RefreshUnit_io_suggestREF ? 3'h5 : _GEN_459; // @[FIFOMASModel.scala 95:33 FIFOMASModel.scala 96:17]
  assign powerStats_powerMonitor_3_io_cmdUsesThisRank = _T_78[3]; // @[FIFOMASModel.scala 162:62]
  assign powerStats_powerMonitor_3_targetFire = targetFire;
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[TimingModel.scala 97:23]
      tCycle <= 64'h0; // @[TimingModel.scala 97:23]
    end else if (targetFire) begin
      tCycle <= _tCycle_T_1; // @[TimingModel.scala 98:10]
    end
    if (reset & targetFire) begin // @[TimingModel.scala 145:29]
      totalReads <= 32'h0; // @[TimingModel.scala 145:29]
    end else if (targetFire) begin
      if (SatUpDownCounter_io_inc) begin // @[TimingModel.scala 147:27]
        totalReads <= _totalReads_T_1; // @[TimingModel.scala 147:40]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 146:30]
      totalWrites <= 32'h0; // @[TimingModel.scala 146:30]
    end else if (targetFire) begin
      if (SatUpDownCounter_1_io_inc) begin // @[TimingModel.scala 148:27]
        totalWrites <= _totalWrites_T_1; // @[TimingModel.scala 148:41]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 154:33]
      totalReadBeats <= 32'h0; // @[TimingModel.scala 154:33]
    end else if (targetFire) begin
      if (_T_1) begin // @[TimingModel.scala 156:24]
        totalReadBeats <= _totalReadBeats_T_1; // @[TimingModel.scala 156:41]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 155:34]
      totalWriteBeats <= 32'h0; // @[TimingModel.scala 155:34]
    end else if (targetFire) begin
      if (_T_5) begin // @[TimingModel.scala 157:24]
        totalWriteBeats <= _totalWriteBeats_T_1; // @[TimingModel.scala 157:42]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 166:63]
      readOutstandingHistogram_0 <= 32'h0; // @[TimingModel.scala 166:63]
    end else if (targetFire) begin
      if (SatUpDownCounter_io_value <= 4'h0) begin // @[TimingModel.scala 171:57]
        readOutstandingHistogram_0 <= _readOutstandingHistogram_0_T_1; // @[TimingModel.scala 172:17]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 166:63]
      readOutstandingHistogram_1 <= 32'h0; // @[TimingModel.scala 166:63]
    end else if (targetFire) begin
      if (~(SatUpDownCounter_io_value <= 4'h0) & SatUpDownCounter_io_value <= 4'h2) begin // @[TimingModel.scala 171:57]
        readOutstandingHistogram_1 <= _readOutstandingHistogram_1_T_1; // @[TimingModel.scala 172:17]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 166:63]
      readOutstandingHistogram_2 <= 32'h0; // @[TimingModel.scala 166:63]
    end else if (targetFire) begin
      if (~_T_31 & SatUpDownCounter_io_value <= 4'h4) begin // @[TimingModel.scala 171:57]
        readOutstandingHistogram_2 <= _readOutstandingHistogram_2_T_1; // @[TimingModel.scala 172:17]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 166:63]
      readOutstandingHistogram_3 <= 32'h0; // @[TimingModel.scala 166:63]
    end else if (targetFire) begin
      if (~_T_36 & SatUpDownCounter_io_value <= 4'h8) begin // @[TimingModel.scala 171:57]
        readOutstandingHistogram_3 <= _readOutstandingHistogram_3_T_1; // @[TimingModel.scala 172:17]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 167:64]
      writeOutstandingHistogram_0 <= 32'h0; // @[TimingModel.scala 167:64]
    end else if (targetFire) begin
      if (SatUpDownCounter_1_io_value <= 4'h0) begin // @[TimingModel.scala 171:57]
        writeOutstandingHistogram_0 <= _writeOutstandingHistogram_0_T_1; // @[TimingModel.scala 172:17]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 167:64]
      writeOutstandingHistogram_1 <= 32'h0; // @[TimingModel.scala 167:64]
    end else if (targetFire) begin
      if (~(SatUpDownCounter_1_io_value <= 4'h0) & SatUpDownCounter_1_io_value <= 4'h2) begin // @[TimingModel.scala 171:57]
        writeOutstandingHistogram_1 <= _writeOutstandingHistogram_1_T_1; // @[TimingModel.scala 172:17]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 167:64]
      writeOutstandingHistogram_2 <= 32'h0; // @[TimingModel.scala 167:64]
    end else if (targetFire) begin
      if (~_T_51 & SatUpDownCounter_1_io_value <= 4'h4) begin // @[TimingModel.scala 171:57]
        writeOutstandingHistogram_2 <= _writeOutstandingHistogram_2_T_1; // @[TimingModel.scala 172:17]
      end
    end
    if (reset & targetFire) begin // @[TimingModel.scala 167:64]
      writeOutstandingHistogram_3 <= 32'h0; // @[TimingModel.scala 167:64]
    end else if (targetFire) begin
      if (~_T_56 & SatUpDownCounter_1_io_value <= 4'h8) begin // @[TimingModel.scala 171:57]
        writeOutstandingHistogram_3 <= _writeOutstandingHistogram_3_T_1; // @[TimingModel.scala 172:17]
      end
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~io_tNasti_ar_valid | io_tNasti_ar_bits_burst == 2'h1 | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Illegal ar request: memory model only supports incrementing bursts\n    at TimingModel.scala:114 assert(!tNasti.ar.valid || (tNasti.ar.bits.burst === NastiConstants.BURST_INCR),\n"
            ); // @[TimingModel.scala 114:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~io_tNasti_ar_valid | io_tNasti_ar_bits_burst == 2'h1 | reset) & targetFire) begin
          $fatal; // @[TimingModel.scala 114:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~(~io_tNasti_aw_valid | io_tNasti_aw_bits_burst == 2'h1 | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Illegal aw request: memory model only supports incrementing bursts\n    at TimingModel.scala:117 assert(!tNasti.aw.valid || (tNasti.aw.bits.burst === NastiConstants.BURST_INCR),\n"
            ); // @[TimingModel.scala 117:9]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~(~io_tNasti_aw_valid | io_tNasti_aw_bits_burst == 2'h1 | reset) & targetFire) begin
          $fatal; // @[TimingModel.scala 117:9]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
  end
// Register and memory initialization
`ifdef RANDOMIZE_GARBAGE_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_INVALID_ASSIGN
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_REG_INIT
`define RANDOMIZE
`endif
`ifdef RANDOMIZE_MEM_INIT
`define RANDOMIZE
`endif
`ifndef RANDOM
`define RANDOM $random
`endif
`ifdef RANDOMIZE_MEM_INIT
  integer initvar;
`endif
`ifndef SYNTHESIS
`ifdef FIRRTL_BEFORE_INITIAL
`FIRRTL_BEFORE_INITIAL
`endif
initial begin
  `ifdef RANDOMIZE
    `ifdef INIT_RANDOM
      `INIT_RANDOM
    `endif
    `ifndef VERILATOR
      `ifdef RANDOMIZE_DELAY
        #`RANDOMIZE_DELAY begin end
      `else
        #0.002 begin end
      `endif
    `endif
`ifdef RANDOMIZE_REG_INIT
  _RAND_0 = {2{`RANDOM}};
  tCycle = _RAND_0[63:0];
  _RAND_1 = {1{`RANDOM}};
  totalReads = _RAND_1[31:0];
  _RAND_2 = {1{`RANDOM}};
  totalWrites = _RAND_2[31:0];
  _RAND_3 = {1{`RANDOM}};
  totalReadBeats = _RAND_3[31:0];
  _RAND_4 = {1{`RANDOM}};
  totalWriteBeats = _RAND_4[31:0];
  _RAND_5 = {1{`RANDOM}};
  readOutstandingHistogram_0 = _RAND_5[31:0];
  _RAND_6 = {1{`RANDOM}};
  readOutstandingHistogram_1 = _RAND_6[31:0];
  _RAND_7 = {1{`RANDOM}};
  readOutstandingHistogram_2 = _RAND_7[31:0];
  _RAND_8 = {1{`RANDOM}};
  readOutstandingHistogram_3 = _RAND_8[31:0];
  _RAND_9 = {1{`RANDOM}};
  writeOutstandingHistogram_0 = _RAND_9[31:0];
  _RAND_10 = {1{`RANDOM}};
  writeOutstandingHistogram_1 = _RAND_10[31:0];
  _RAND_11 = {1{`RANDOM}};
  writeOutstandingHistogram_2 = _RAND_11[31:0];
  _RAND_12 = {1{`RANDOM}};
  writeOutstandingHistogram_3 = _RAND_12[31:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule
