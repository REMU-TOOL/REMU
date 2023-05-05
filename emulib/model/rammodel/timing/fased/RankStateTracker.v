module emulib_fased_RankStateTracker(
  input         clock,
  input         reset,
  input  [6:0]  io_timings_tAL,
  input  [6:0]  io_timings_tCAS,
  input  [6:0]  io_timings_tCWD,
  input  [6:0]  io_timings_tCCD,
  input  [6:0]  io_timings_tFAW,
  input  [6:0]  io_timings_tRAS,
  input  [13:0] io_timings_tREFI,
  input  [6:0]  io_timings_tRC,
  input  [6:0]  io_timings_tRCD,
  input  [9:0]  io_timings_tRFC,
  input  [6:0]  io_timings_tRRD,
  input  [6:0]  io_timings_tRP,
  input  [6:0]  io_timings_tRTP,
  input  [6:0]  io_timings_tRTRS,
  input  [6:0]  io_timings_tWR,
  input  [6:0]  io_timings_tWTR,
  input  [2:0]  io_selectedCmd,
  input         io_autoPRE,
  input  [25:0] io_cmdRow,
  output        io_rank_canCASW,
  output        io_rank_canCASR,
  output        io_rank_canPRE,
  output        io_rank_canACT,
  output        io_rank_canREF,
  output        io_rank_wantREF,
  output        io_rank_state,
  output        io_rank_banks_0_canCASW,
  output        io_rank_banks_0_canCASR,
  output        io_rank_banks_0_canPRE,
  output        io_rank_banks_0_canACT,
  output [25:0] io_rank_banks_0_openRow,
  output        io_rank_banks_0_state,
  output        io_rank_banks_1_canCASW,
  output        io_rank_banks_1_canCASR,
  output        io_rank_banks_1_canPRE,
  output        io_rank_banks_1_canACT,
  output [25:0] io_rank_banks_1_openRow,
  output        io_rank_banks_1_state,
  output        io_rank_banks_2_canCASW,
  output        io_rank_banks_2_canCASR,
  output        io_rank_banks_2_canPRE,
  output        io_rank_banks_2_canACT,
  output [25:0] io_rank_banks_2_openRow,
  output        io_rank_banks_2_state,
  output        io_rank_banks_3_canCASW,
  output        io_rank_banks_3_canCASR,
  output        io_rank_banks_3_canPRE,
  output        io_rank_banks_3_canACT,
  output [25:0] io_rank_banks_3_openRow,
  output        io_rank_banks_3_state,
  output        io_rank_banks_4_canCASW,
  output        io_rank_banks_4_canCASR,
  output        io_rank_banks_4_canPRE,
  output        io_rank_banks_4_canACT,
  output [25:0] io_rank_banks_4_openRow,
  output        io_rank_banks_4_state,
  output        io_rank_banks_5_canCASW,
  output        io_rank_banks_5_canCASR,
  output        io_rank_banks_5_canPRE,
  output        io_rank_banks_5_canACT,
  output [25:0] io_rank_banks_5_openRow,
  output        io_rank_banks_5_state,
  output        io_rank_banks_6_canCASW,
  output        io_rank_banks_6_canCASR,
  output        io_rank_banks_6_canPRE,
  output        io_rank_banks_6_canACT,
  output [25:0] io_rank_banks_6_openRow,
  output        io_rank_banks_6_state,
  output        io_rank_banks_7_canCASW,
  output        io_rank_banks_7_canCASR,
  output        io_rank_banks_7_canPRE,
  output        io_rank_banks_7_canACT,
  output [25:0] io_rank_banks_7_openRow,
  output        io_rank_banks_7_state,
  input  [6:0]  io_tCycle,
  input         io_cmdUsesThisRank,
  input  [7:0]  io_cmdBankOH,
  input         targetFire
);
`ifdef RANDOMIZE_REG_INIT
  reg [31:0] _RAND_0;
  reg [31:0] _RAND_1;
  reg [31:0] _RAND_2;
`endif // RANDOMIZE_REG_INIT
  wire  nextLegalPRE_clock;
  wire  nextLegalPRE_reset;
  wire  nextLegalPRE_io_set_valid;
  wire [6:0] nextLegalPRE_io_set_bits;
  wire  nextLegalPRE_io_idle;
  wire  nextLegalPRE_targetFire;
  wire  nextLegalACT_clock;
  wire  nextLegalACT_reset;
  wire  nextLegalACT_io_set_valid;
  wire [9:0] nextLegalACT_io_set_bits;
  wire [9:0] nextLegalACT_io_current;
  wire  nextLegalACT_io_idle;
  wire  nextLegalACT_targetFire;
  wire  nextLegalCASR_clock;
  wire  nextLegalCASR_reset;
  wire  nextLegalCASR_io_set_valid;
  wire [6:0] nextLegalCASR_io_set_bits;
  wire  nextLegalCASR_io_idle;
  wire  nextLegalCASR_targetFire;
  wire  nextLegalCASW_clock;
  wire  nextLegalCASW_reset;
  wire  nextLegalCASW_io_set_valid;
  wire [6:0] nextLegalCASW_io_set_bits;
  wire  nextLegalCASW_io_idle;
  wire  nextLegalCASW_targetFire;
  wire  tFAWcheck_clock;
  wire  tFAWcheck_reset;
  wire  tFAWcheck_io_enq_ready;
  wire  tFAWcheck_io_enq_valid;
  wire [6:0] tFAWcheck_io_enq_bits;
  wire  tFAWcheck_io_deq_ready;
  wire  tFAWcheck_io_deq_valid;
  wire [6:0] tFAWcheck_io_deq_bits;
  wire  tFAWcheck_targetFire;
  wire  BankStateTracker_clock;
  wire  BankStateTracker_reset;
  wire [6:0] BankStateTracker_io_timings_tAL;
  wire [6:0] BankStateTracker_io_timings_tCWD;
  wire [6:0] BankStateTracker_io_timings_tCCD;
  wire [6:0] BankStateTracker_io_timings_tRAS;
  wire [6:0] BankStateTracker_io_timings_tRC;
  wire [6:0] BankStateTracker_io_timings_tRCD;
  wire [6:0] BankStateTracker_io_timings_tRP;
  wire [6:0] BankStateTracker_io_timings_tRTP;
  wire [6:0] BankStateTracker_io_timings_tWR;
  wire [2:0] BankStateTracker_io_selectedCmd;
  wire  BankStateTracker_io_autoPRE;
  wire [25:0] BankStateTracker_io_cmdRow;
  wire  BankStateTracker_io_out_canCASW;
  wire  BankStateTracker_io_out_canCASR;
  wire  BankStateTracker_io_out_canPRE;
  wire  BankStateTracker_io_out_canACT;
  wire [25:0] BankStateTracker_io_out_openRow;
  wire  BankStateTracker_io_out_state;
  wire  BankStateTracker_io_cmdUsesThisBank;
  wire  BankStateTracker_targetFire;
  wire  BankStateTracker_1_clock;
  wire  BankStateTracker_1_reset;
  wire [6:0] BankStateTracker_1_io_timings_tAL;
  wire [6:0] BankStateTracker_1_io_timings_tCWD;
  wire [6:0] BankStateTracker_1_io_timings_tCCD;
  wire [6:0] BankStateTracker_1_io_timings_tRAS;
  wire [6:0] BankStateTracker_1_io_timings_tRC;
  wire [6:0] BankStateTracker_1_io_timings_tRCD;
  wire [6:0] BankStateTracker_1_io_timings_tRP;
  wire [6:0] BankStateTracker_1_io_timings_tRTP;
  wire [6:0] BankStateTracker_1_io_timings_tWR;
  wire [2:0] BankStateTracker_1_io_selectedCmd;
  wire  BankStateTracker_1_io_autoPRE;
  wire [25:0] BankStateTracker_1_io_cmdRow;
  wire  BankStateTracker_1_io_out_canCASW;
  wire  BankStateTracker_1_io_out_canCASR;
  wire  BankStateTracker_1_io_out_canPRE;
  wire  BankStateTracker_1_io_out_canACT;
  wire [25:0] BankStateTracker_1_io_out_openRow;
  wire  BankStateTracker_1_io_out_state;
  wire  BankStateTracker_1_io_cmdUsesThisBank;
  wire  BankStateTracker_1_targetFire;
  wire  BankStateTracker_2_clock;
  wire  BankStateTracker_2_reset;
  wire [6:0] BankStateTracker_2_io_timings_tAL;
  wire [6:0] BankStateTracker_2_io_timings_tCWD;
  wire [6:0] BankStateTracker_2_io_timings_tCCD;
  wire [6:0] BankStateTracker_2_io_timings_tRAS;
  wire [6:0] BankStateTracker_2_io_timings_tRC;
  wire [6:0] BankStateTracker_2_io_timings_tRCD;
  wire [6:0] BankStateTracker_2_io_timings_tRP;
  wire [6:0] BankStateTracker_2_io_timings_tRTP;
  wire [6:0] BankStateTracker_2_io_timings_tWR;
  wire [2:0] BankStateTracker_2_io_selectedCmd;
  wire  BankStateTracker_2_io_autoPRE;
  wire [25:0] BankStateTracker_2_io_cmdRow;
  wire  BankStateTracker_2_io_out_canCASW;
  wire  BankStateTracker_2_io_out_canCASR;
  wire  BankStateTracker_2_io_out_canPRE;
  wire  BankStateTracker_2_io_out_canACT;
  wire [25:0] BankStateTracker_2_io_out_openRow;
  wire  BankStateTracker_2_io_out_state;
  wire  BankStateTracker_2_io_cmdUsesThisBank;
  wire  BankStateTracker_2_targetFire;
  wire  BankStateTracker_3_clock;
  wire  BankStateTracker_3_reset;
  wire [6:0] BankStateTracker_3_io_timings_tAL;
  wire [6:0] BankStateTracker_3_io_timings_tCWD;
  wire [6:0] BankStateTracker_3_io_timings_tCCD;
  wire [6:0] BankStateTracker_3_io_timings_tRAS;
  wire [6:0] BankStateTracker_3_io_timings_tRC;
  wire [6:0] BankStateTracker_3_io_timings_tRCD;
  wire [6:0] BankStateTracker_3_io_timings_tRP;
  wire [6:0] BankStateTracker_3_io_timings_tRTP;
  wire [6:0] BankStateTracker_3_io_timings_tWR;
  wire [2:0] BankStateTracker_3_io_selectedCmd;
  wire  BankStateTracker_3_io_autoPRE;
  wire [25:0] BankStateTracker_3_io_cmdRow;
  wire  BankStateTracker_3_io_out_canCASW;
  wire  BankStateTracker_3_io_out_canCASR;
  wire  BankStateTracker_3_io_out_canPRE;
  wire  BankStateTracker_3_io_out_canACT;
  wire [25:0] BankStateTracker_3_io_out_openRow;
  wire  BankStateTracker_3_io_out_state;
  wire  BankStateTracker_3_io_cmdUsesThisBank;
  wire  BankStateTracker_3_targetFire;
  wire  BankStateTracker_4_clock;
  wire  BankStateTracker_4_reset;
  wire [6:0] BankStateTracker_4_io_timings_tAL;
  wire [6:0] BankStateTracker_4_io_timings_tCWD;
  wire [6:0] BankStateTracker_4_io_timings_tCCD;
  wire [6:0] BankStateTracker_4_io_timings_tRAS;
  wire [6:0] BankStateTracker_4_io_timings_tRC;
  wire [6:0] BankStateTracker_4_io_timings_tRCD;
  wire [6:0] BankStateTracker_4_io_timings_tRP;
  wire [6:0] BankStateTracker_4_io_timings_tRTP;
  wire [6:0] BankStateTracker_4_io_timings_tWR;
  wire [2:0] BankStateTracker_4_io_selectedCmd;
  wire  BankStateTracker_4_io_autoPRE;
  wire [25:0] BankStateTracker_4_io_cmdRow;
  wire  BankStateTracker_4_io_out_canCASW;
  wire  BankStateTracker_4_io_out_canCASR;
  wire  BankStateTracker_4_io_out_canPRE;
  wire  BankStateTracker_4_io_out_canACT;
  wire [25:0] BankStateTracker_4_io_out_openRow;
  wire  BankStateTracker_4_io_out_state;
  wire  BankStateTracker_4_io_cmdUsesThisBank;
  wire  BankStateTracker_4_targetFire;
  wire  BankStateTracker_5_clock;
  wire  BankStateTracker_5_reset;
  wire [6:0] BankStateTracker_5_io_timings_tAL;
  wire [6:0] BankStateTracker_5_io_timings_tCWD;
  wire [6:0] BankStateTracker_5_io_timings_tCCD;
  wire [6:0] BankStateTracker_5_io_timings_tRAS;
  wire [6:0] BankStateTracker_5_io_timings_tRC;
  wire [6:0] BankStateTracker_5_io_timings_tRCD;
  wire [6:0] BankStateTracker_5_io_timings_tRP;
  wire [6:0] BankStateTracker_5_io_timings_tRTP;
  wire [6:0] BankStateTracker_5_io_timings_tWR;
  wire [2:0] BankStateTracker_5_io_selectedCmd;
  wire  BankStateTracker_5_io_autoPRE;
  wire [25:0] BankStateTracker_5_io_cmdRow;
  wire  BankStateTracker_5_io_out_canCASW;
  wire  BankStateTracker_5_io_out_canCASR;
  wire  BankStateTracker_5_io_out_canPRE;
  wire  BankStateTracker_5_io_out_canACT;
  wire [25:0] BankStateTracker_5_io_out_openRow;
  wire  BankStateTracker_5_io_out_state;
  wire  BankStateTracker_5_io_cmdUsesThisBank;
  wire  BankStateTracker_5_targetFire;
  wire  BankStateTracker_6_clock;
  wire  BankStateTracker_6_reset;
  wire [6:0] BankStateTracker_6_io_timings_tAL;
  wire [6:0] BankStateTracker_6_io_timings_tCWD;
  wire [6:0] BankStateTracker_6_io_timings_tCCD;
  wire [6:0] BankStateTracker_6_io_timings_tRAS;
  wire [6:0] BankStateTracker_6_io_timings_tRC;
  wire [6:0] BankStateTracker_6_io_timings_tRCD;
  wire [6:0] BankStateTracker_6_io_timings_tRP;
  wire [6:0] BankStateTracker_6_io_timings_tRTP;
  wire [6:0] BankStateTracker_6_io_timings_tWR;
  wire [2:0] BankStateTracker_6_io_selectedCmd;
  wire  BankStateTracker_6_io_autoPRE;
  wire [25:0] BankStateTracker_6_io_cmdRow;
  wire  BankStateTracker_6_io_out_canCASW;
  wire  BankStateTracker_6_io_out_canCASR;
  wire  BankStateTracker_6_io_out_canPRE;
  wire  BankStateTracker_6_io_out_canACT;
  wire [25:0] BankStateTracker_6_io_out_openRow;
  wire  BankStateTracker_6_io_out_state;
  wire  BankStateTracker_6_io_cmdUsesThisBank;
  wire  BankStateTracker_6_targetFire;
  wire  BankStateTracker_7_clock;
  wire  BankStateTracker_7_reset;
  wire [6:0] BankStateTracker_7_io_timings_tAL;
  wire [6:0] BankStateTracker_7_io_timings_tCWD;
  wire [6:0] BankStateTracker_7_io_timings_tCCD;
  wire [6:0] BankStateTracker_7_io_timings_tRAS;
  wire [6:0] BankStateTracker_7_io_timings_tRC;
  wire [6:0] BankStateTracker_7_io_timings_tRCD;
  wire [6:0] BankStateTracker_7_io_timings_tRP;
  wire [6:0] BankStateTracker_7_io_timings_tRTP;
  wire [6:0] BankStateTracker_7_io_timings_tWR;
  wire [2:0] BankStateTracker_7_io_selectedCmd;
  wire  BankStateTracker_7_io_autoPRE;
  wire [25:0] BankStateTracker_7_io_cmdRow;
  wire  BankStateTracker_7_io_out_canCASW;
  wire  BankStateTracker_7_io_out_canCASR;
  wire  BankStateTracker_7_io_out_canPRE;
  wire  BankStateTracker_7_io_out_canACT;
  wire [25:0] BankStateTracker_7_io_out_openRow;
  wire  BankStateTracker_7_io_out_state;
  wire  BankStateTracker_7_io_cmdUsesThisBank;
  wire  BankStateTracker_7_targetFire;
  reg [13:0] tREFI; // @[DramCommon.scala 479:22]
  reg  state; // @[DramCommon.scala 480:22]
  reg  wantREF; // @[DramCommon.scala 481:24]
  wire  _tFAWcheck_io_enq_valid_T_1 = io_cmdUsesThisRank & io_selectedCmd == 3'h1; // @[DramCommon.scala 490:48]
  wire [6:0] _nextLegalACT_io_set_bits_T_1 = io_timings_tRRD - 7'h1; // @[DramCommon.scala 497:49]
  wire  _T_5 = io_selectedCmd == 3'h4; // @[DramCommon.scala 499:30]
  wire  _T_6 = ~io_cmdUsesThisRank; // @[DramCommon.scala 500:12]
  wire [6:0] _nextLegalCASR_io_set_bits_T = io_cmdUsesThisRank ? 7'h0 : io_timings_tRTRS; // @[DramCommon.scala 504:10]
  wire [6:0] _nextLegalCASR_io_set_bits_T_2 = io_timings_tCCD + _nextLegalCASR_io_set_bits_T; // @[DramCommon.scala 503:50]
  wire [6:0] _nextLegalCASR_io_set_bits_T_4 = _nextLegalCASR_io_set_bits_T_2 - 7'h1; // @[DramCommon.scala 504:54]
  wire [6:0] _nextLegalCASW_io_set_bits_T_1 = io_timings_tCAS + io_timings_tCCD; // @[DramCommon.scala 508:50]
  wire [6:0] _nextLegalCASW_io_set_bits_T_3 = _nextLegalCASW_io_set_bits_T_1 - io_timings_tCWD; // @[DramCommon.scala 508:68]
  wire [6:0] _nextLegalCASW_io_set_bits_T_5 = _nextLegalCASW_io_set_bits_T_3 + io_timings_tRTRS; // @[DramCommon.scala 508:86]
  wire [6:0] _nextLegalCASW_io_set_bits_T_7 = _nextLegalCASW_io_set_bits_T_5 - 7'h1; // @[DramCommon.scala 509:24]
  wire  _T_11 = io_selectedCmd == 3'h3; // @[DramCommon.scala 511:30]
  wire [6:0] _nextLegalCASR_io_set_bits_T_6 = io_timings_tCWD + io_timings_tCCD; // @[DramCommon.scala 516:23]
  wire [6:0] _nextLegalCASR_io_set_bits_T_8 = _nextLegalCASR_io_set_bits_T_6 + io_timings_tWTR; // @[DramCommon.scala 516:41]
  wire [6:0] _nextLegalCASR_io_set_bits_T_10 = _nextLegalCASR_io_set_bits_T_8 - 7'h1; // @[DramCommon.scala 516:59]
  wire [6:0] _nextLegalCASR_io_set_bits_T_14 = _nextLegalCASR_io_set_bits_T_6 + io_timings_tRTRS; // @[DramCommon.scala 517:41]
  wire [6:0] _nextLegalCASR_io_set_bits_T_16 = _nextLegalCASR_io_set_bits_T_14 - io_timings_tCAS; // @[DramCommon.scala 517:60]
  wire [6:0] _nextLegalCASR_io_set_bits_T_18 = _nextLegalCASR_io_set_bits_T_16 - 7'h1; // @[DramCommon.scala 517:78]
  wire [6:0] _nextLegalCASR_io_set_bits_T_19 = io_cmdUsesThisRank ? _nextLegalCASR_io_set_bits_T_10 :
    _nextLegalCASR_io_set_bits_T_18; // @[DramCommon.scala 515:37]
  wire [6:0] _nextLegalCASW_io_set_bits_T_9 = io_timings_tCCD - 7'h1; // @[DramCommon.scala 521:50]
  wire  _T_18 = io_cmdUsesThisRank & io_selectedCmd == 3'h2; // @[DramCommon.scala 523:34]
  wire  _T_23 = io_cmdUsesThisRank & io_selectedCmd == 3'h5; // @[DramCommon.scala 526:34]
  wire [9:0] _nextLegalACT_io_set_bits_T_3 = io_timings_tRFC - 10'h1; // @[DramCommon.scala 531:51]
  wire  _GEN_0 = io_cmdUsesThisRank & io_selectedCmd == 3'h5 ? 1'h0 : wantREF; // @[DramCommon.scala 526:65 DramCommon.scala 528:15 DramCommon.scala 481:24]
  wire  _GEN_1 = io_cmdUsesThisRank & io_selectedCmd == 3'h5 | state; // @[DramCommon.scala 526:65 DramCommon.scala 529:13 DramCommon.scala 480:22]
  wire  _GEN_4 = io_cmdUsesThisRank & io_selectedCmd == 3'h2 ? wantREF : _GEN_0; // @[DramCommon.scala 523:65 DramCommon.scala 481:24]
  wire  _GEN_5 = io_cmdUsesThisRank & io_selectedCmd == 3'h2 ? state : _GEN_1; // @[DramCommon.scala 523:65 DramCommon.scala 480:22]
  wire  _GEN_6 = io_cmdUsesThisRank & io_selectedCmd == 3'h2 ? 1'h0 : _T_23; // @[DramCommon.scala 523:65 DramCommon.scala 485:22]
  wire  _GEN_11 = io_selectedCmd == 3'h3 ? wantREF : _GEN_4; // @[DramCommon.scala 511:44 DramCommon.scala 481:24]
  wire  _GEN_12 = io_selectedCmd == 3'h3 ? state : _GEN_5; // @[DramCommon.scala 511:44 DramCommon.scala 480:22]
  wire  _GEN_13 = io_selectedCmd == 3'h3 ? 1'h0 : _GEN_6; // @[DramCommon.scala 511:44 DramCommon.scala 485:22]
  wire  _GEN_15 = io_selectedCmd == 3'h4 | _T_11; // @[DramCommon.scala 499:44 DramCommon.scala 502:32]
  wire  _GEN_18 = io_selectedCmd == 3'h4 ? wantREF : _GEN_11; // @[DramCommon.scala 499:44 DramCommon.scala 481:24]
  wire  _GEN_19 = io_selectedCmd == 3'h4 ? state : _GEN_12; // @[DramCommon.scala 499:44 DramCommon.scala 480:22]
  wire  _GEN_20 = io_selectedCmd == 3'h4 ? 1'h0 : _GEN_13; // @[DramCommon.scala 499:44 DramCommon.scala 485:22]
  wire  _GEN_27 = _tFAWcheck_io_enq_valid_T_1 ? wantREF : _GEN_18; // @[DramCommon.scala 494:59 DramCommon.scala 481:24]
  wire [13:0] _tREFI_T_1 = tREFI + 14'h1; // @[DramCommon.scala 539:20]
  wire  _GEN_30 = tREFI == io_timings_tREFI & io_timings_tREFI != 14'h0 | _GEN_27; // @[DramCommon.scala 535:65 DramCommon.scala 537:13]
  wire  _GEN_37 = ~_tFAWcheck_io_enq_valid_T_1; // @[DramCommon.scala 500:11]
  wire  _GEN_45 = _GEN_37 & ~_T_5; // @[DramCommon.scala 512:11]
  wire  _GEN_57 = _GEN_45 & ~_T_11; // @[DramCommon.scala 524:13]
  emulib_fased_DownCounter nextLegalPRE (
    .clock(nextLegalPRE_clock),
    .reset(nextLegalPRE_reset),
    .io_set_valid(nextLegalPRE_io_set_valid),
    .io_set_bits(nextLegalPRE_io_set_bits),
    .io_idle(nextLegalPRE_io_idle),
    .targetFire(nextLegalPRE_targetFire)
  );
  emulib_fased_DownCounter_2 nextLegalACT (
    .clock(nextLegalACT_clock),
    .reset(nextLegalACT_reset),
    .io_set_valid(nextLegalACT_io_set_valid),
    .io_set_bits(nextLegalACT_io_set_bits),
    .io_current(nextLegalACT_io_current),
    .io_idle(nextLegalACT_io_idle),
    .targetFire(nextLegalACT_targetFire)
  );
  emulib_fased_DownCounter nextLegalCASR (
    .clock(nextLegalCASR_clock),
    .reset(nextLegalCASR_reset),
    .io_set_valid(nextLegalCASR_io_set_valid),
    .io_set_bits(nextLegalCASR_io_set_bits),
    .io_idle(nextLegalCASR_io_idle),
    .targetFire(nextLegalCASR_targetFire)
  );
  emulib_fased_DownCounter nextLegalCASW (
    .clock(nextLegalCASW_clock),
    .reset(nextLegalCASW_reset),
    .io_set_valid(nextLegalCASW_io_set_valid),
    .io_set_bits(nextLegalCASW_io_set_bits),
    .io_idle(nextLegalCASW_io_idle),
    .targetFire(nextLegalCASW_targetFire)
  );
  emulib_fased_Queue_17_0 tFAWcheck (
    .clock(tFAWcheck_clock),
    .reset(tFAWcheck_reset),
    .io_enq_ready(tFAWcheck_io_enq_ready),
    .io_enq_valid(tFAWcheck_io_enq_valid),
    .io_enq_bits(tFAWcheck_io_enq_bits),
    .io_deq_ready(tFAWcheck_io_deq_ready),
    .io_deq_valid(tFAWcheck_io_deq_valid),
    .io_deq_bits(tFAWcheck_io_deq_bits),
    .targetFire(tFAWcheck_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker (
    .clock(BankStateTracker_clock),
    .reset(BankStateTracker_reset),
    .io_timings_tAL(BankStateTracker_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_io_selectedCmd),
    .io_autoPRE(BankStateTracker_io_autoPRE),
    .io_cmdRow(BankStateTracker_io_cmdRow),
    .io_out_canCASW(BankStateTracker_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_io_out_canPRE),
    .io_out_canACT(BankStateTracker_io_out_canACT),
    .io_out_openRow(BankStateTracker_io_out_openRow),
    .io_out_state(BankStateTracker_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker_1 (
    .clock(BankStateTracker_1_clock),
    .reset(BankStateTracker_1_reset),
    .io_timings_tAL(BankStateTracker_1_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_1_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_1_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_1_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_1_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_1_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_1_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_1_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_1_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_1_io_selectedCmd),
    .io_autoPRE(BankStateTracker_1_io_autoPRE),
    .io_cmdRow(BankStateTracker_1_io_cmdRow),
    .io_out_canCASW(BankStateTracker_1_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_1_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_1_io_out_canPRE),
    .io_out_canACT(BankStateTracker_1_io_out_canACT),
    .io_out_openRow(BankStateTracker_1_io_out_openRow),
    .io_out_state(BankStateTracker_1_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_1_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_1_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker_2 (
    .clock(BankStateTracker_2_clock),
    .reset(BankStateTracker_2_reset),
    .io_timings_tAL(BankStateTracker_2_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_2_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_2_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_2_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_2_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_2_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_2_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_2_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_2_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_2_io_selectedCmd),
    .io_autoPRE(BankStateTracker_2_io_autoPRE),
    .io_cmdRow(BankStateTracker_2_io_cmdRow),
    .io_out_canCASW(BankStateTracker_2_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_2_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_2_io_out_canPRE),
    .io_out_canACT(BankStateTracker_2_io_out_canACT),
    .io_out_openRow(BankStateTracker_2_io_out_openRow),
    .io_out_state(BankStateTracker_2_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_2_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_2_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker_3 (
    .clock(BankStateTracker_3_clock),
    .reset(BankStateTracker_3_reset),
    .io_timings_tAL(BankStateTracker_3_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_3_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_3_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_3_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_3_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_3_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_3_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_3_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_3_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_3_io_selectedCmd),
    .io_autoPRE(BankStateTracker_3_io_autoPRE),
    .io_cmdRow(BankStateTracker_3_io_cmdRow),
    .io_out_canCASW(BankStateTracker_3_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_3_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_3_io_out_canPRE),
    .io_out_canACT(BankStateTracker_3_io_out_canACT),
    .io_out_openRow(BankStateTracker_3_io_out_openRow),
    .io_out_state(BankStateTracker_3_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_3_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_3_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker_4 (
    .clock(BankStateTracker_4_clock),
    .reset(BankStateTracker_4_reset),
    .io_timings_tAL(BankStateTracker_4_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_4_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_4_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_4_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_4_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_4_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_4_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_4_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_4_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_4_io_selectedCmd),
    .io_autoPRE(BankStateTracker_4_io_autoPRE),
    .io_cmdRow(BankStateTracker_4_io_cmdRow),
    .io_out_canCASW(BankStateTracker_4_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_4_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_4_io_out_canPRE),
    .io_out_canACT(BankStateTracker_4_io_out_canACT),
    .io_out_openRow(BankStateTracker_4_io_out_openRow),
    .io_out_state(BankStateTracker_4_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_4_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_4_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker_5 (
    .clock(BankStateTracker_5_clock),
    .reset(BankStateTracker_5_reset),
    .io_timings_tAL(BankStateTracker_5_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_5_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_5_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_5_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_5_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_5_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_5_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_5_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_5_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_5_io_selectedCmd),
    .io_autoPRE(BankStateTracker_5_io_autoPRE),
    .io_cmdRow(BankStateTracker_5_io_cmdRow),
    .io_out_canCASW(BankStateTracker_5_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_5_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_5_io_out_canPRE),
    .io_out_canACT(BankStateTracker_5_io_out_canACT),
    .io_out_openRow(BankStateTracker_5_io_out_openRow),
    .io_out_state(BankStateTracker_5_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_5_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_5_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker_6 (
    .clock(BankStateTracker_6_clock),
    .reset(BankStateTracker_6_reset),
    .io_timings_tAL(BankStateTracker_6_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_6_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_6_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_6_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_6_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_6_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_6_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_6_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_6_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_6_io_selectedCmd),
    .io_autoPRE(BankStateTracker_6_io_autoPRE),
    .io_cmdRow(BankStateTracker_6_io_cmdRow),
    .io_out_canCASW(BankStateTracker_6_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_6_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_6_io_out_canPRE),
    .io_out_canACT(BankStateTracker_6_io_out_canACT),
    .io_out_openRow(BankStateTracker_6_io_out_openRow),
    .io_out_state(BankStateTracker_6_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_6_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_6_targetFire)
  );
  emulib_fased_BankStateTracker BankStateTracker_7 (
    .clock(BankStateTracker_7_clock),
    .reset(BankStateTracker_7_reset),
    .io_timings_tAL(BankStateTracker_7_io_timings_tAL),
    .io_timings_tCWD(BankStateTracker_7_io_timings_tCWD),
    .io_timings_tCCD(BankStateTracker_7_io_timings_tCCD),
    .io_timings_tRAS(BankStateTracker_7_io_timings_tRAS),
    .io_timings_tRC(BankStateTracker_7_io_timings_tRC),
    .io_timings_tRCD(BankStateTracker_7_io_timings_tRCD),
    .io_timings_tRP(BankStateTracker_7_io_timings_tRP),
    .io_timings_tRTP(BankStateTracker_7_io_timings_tRTP),
    .io_timings_tWR(BankStateTracker_7_io_timings_tWR),
    .io_selectedCmd(BankStateTracker_7_io_selectedCmd),
    .io_autoPRE(BankStateTracker_7_io_autoPRE),
    .io_cmdRow(BankStateTracker_7_io_cmdRow),
    .io_out_canCASW(BankStateTracker_7_io_out_canCASW),
    .io_out_canCASR(BankStateTracker_7_io_out_canCASR),
    .io_out_canPRE(BankStateTracker_7_io_out_canPRE),
    .io_out_canACT(BankStateTracker_7_io_out_canACT),
    .io_out_openRow(BankStateTracker_7_io_out_openRow),
    .io_out_state(BankStateTracker_7_io_out_state),
    .io_cmdUsesThisBank(BankStateTracker_7_io_cmdUsesThisBank),
    .targetFire(BankStateTracker_7_targetFire)
  );
  assign io_rank_canCASW = nextLegalCASW_io_idle; // @[DramCommon.scala 559:19]
  assign io_rank_canCASR = nextLegalCASR_io_idle; // @[DramCommon.scala 558:19]
  assign io_rank_canPRE = nextLegalPRE_io_idle; // @[DramCommon.scala 560:18]
  assign io_rank_canACT = nextLegalACT_io_idle & tFAWcheck_io_enq_ready; // @[DramCommon.scala 561:42]
  assign io_rank_canREF = BankStateTracker_io_out_canACT & BankStateTracker_1_io_out_canACT &
    BankStateTracker_2_io_out_canACT & BankStateTracker_3_io_out_canACT & BankStateTracker_4_io_out_canACT &
    BankStateTracker_5_io_out_canACT & BankStateTracker_6_io_out_canACT & BankStateTracker_7_io_out_canACT; // @[DramCommon.scala 557:68]
  assign io_rank_wantREF = wantREF; // @[DramCommon.scala 562:19]
  assign io_rank_state = state; // @[DramCommon.scala 563:17]
  assign io_rank_banks_0_canCASW = BankStateTracker_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_0_canCASR = BankStateTracker_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_0_canPRE = BankStateTracker_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_0_canACT = BankStateTracker_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_0_openRow = BankStateTracker_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_0_state = BankStateTracker_io_out_state; // @[DramCommon.scala 547:69]
  assign io_rank_banks_1_canCASW = BankStateTracker_1_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_1_canCASR = BankStateTracker_1_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_1_canPRE = BankStateTracker_1_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_1_canACT = BankStateTracker_1_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_1_openRow = BankStateTracker_1_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_1_state = BankStateTracker_1_io_out_state; // @[DramCommon.scala 547:69]
  assign io_rank_banks_2_canCASW = BankStateTracker_2_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_2_canCASR = BankStateTracker_2_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_2_canPRE = BankStateTracker_2_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_2_canACT = BankStateTracker_2_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_2_openRow = BankStateTracker_2_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_2_state = BankStateTracker_2_io_out_state; // @[DramCommon.scala 547:69]
  assign io_rank_banks_3_canCASW = BankStateTracker_3_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_3_canCASR = BankStateTracker_3_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_3_canPRE = BankStateTracker_3_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_3_canACT = BankStateTracker_3_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_3_openRow = BankStateTracker_3_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_3_state = BankStateTracker_3_io_out_state; // @[DramCommon.scala 547:69]
  assign io_rank_banks_4_canCASW = BankStateTracker_4_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_4_canCASR = BankStateTracker_4_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_4_canPRE = BankStateTracker_4_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_4_canACT = BankStateTracker_4_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_4_openRow = BankStateTracker_4_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_4_state = BankStateTracker_4_io_out_state; // @[DramCommon.scala 547:69]
  assign io_rank_banks_5_canCASW = BankStateTracker_5_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_5_canCASR = BankStateTracker_5_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_5_canPRE = BankStateTracker_5_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_5_canACT = BankStateTracker_5_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_5_openRow = BankStateTracker_5_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_5_state = BankStateTracker_5_io_out_state; // @[DramCommon.scala 547:69]
  assign io_rank_banks_6_canCASW = BankStateTracker_6_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_6_canCASR = BankStateTracker_6_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_6_canPRE = BankStateTracker_6_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_6_canACT = BankStateTracker_6_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_6_openRow = BankStateTracker_6_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_6_state = BankStateTracker_6_io_out_state; // @[DramCommon.scala 547:69]
  assign io_rank_banks_7_canCASW = BankStateTracker_7_io_out_canCASW; // @[DramCommon.scala 547:69]
  assign io_rank_banks_7_canCASR = BankStateTracker_7_io_out_canCASR; // @[DramCommon.scala 547:69]
  assign io_rank_banks_7_canPRE = BankStateTracker_7_io_out_canPRE; // @[DramCommon.scala 547:69]
  assign io_rank_banks_7_canACT = BankStateTracker_7_io_out_canACT; // @[DramCommon.scala 547:69]
  assign io_rank_banks_7_openRow = BankStateTracker_7_io_out_openRow; // @[DramCommon.scala 547:69]
  assign io_rank_banks_7_state = BankStateTracker_7_io_out_state; // @[DramCommon.scala 547:69]
  assign nextLegalPRE_clock = clock;
  assign nextLegalPRE_reset = reset;
  assign nextLegalPRE_io_set_valid = 1'h0; // @[DramCommon.scala 485:22]
  assign nextLegalPRE_io_set_bits = 7'h0;
  assign nextLegalPRE_targetFire = targetFire;
  assign nextLegalACT_clock = clock;
  assign nextLegalACT_reset = reset;
  assign nextLegalACT_io_set_valid = _tFAWcheck_io_enq_valid_T_1 | _GEN_20; // @[DramCommon.scala 494:59 DramCommon.scala 496:31]
  assign nextLegalACT_io_set_bits = _tFAWcheck_io_enq_valid_T_1 ? {{3'd0}, _nextLegalACT_io_set_bits_T_1} :
    _nextLegalACT_io_set_bits_T_3; // @[DramCommon.scala 494:59 DramCommon.scala 497:30]
  assign nextLegalACT_targetFire = targetFire;
  assign nextLegalCASR_clock = clock;
  assign nextLegalCASR_reset = reset;
  assign nextLegalCASR_io_set_valid = _tFAWcheck_io_enq_valid_T_1 ? 1'h0 : _GEN_15; // @[DramCommon.scala 494:59 DramCommon.scala 485:22]
  assign nextLegalCASR_io_set_bits = io_selectedCmd == 3'h4 ? _nextLegalCASR_io_set_bits_T_4 :
    _nextLegalCASR_io_set_bits_T_19; // @[DramCommon.scala 499:44 DramCommon.scala 503:31]
  assign nextLegalCASR_targetFire = targetFire;
  assign nextLegalCASW_clock = clock;
  assign nextLegalCASW_reset = reset;
  assign nextLegalCASW_io_set_valid = _tFAWcheck_io_enq_valid_T_1 ? 1'h0 : _GEN_15; // @[DramCommon.scala 494:59 DramCommon.scala 485:22]
  assign nextLegalCASW_io_set_bits = io_selectedCmd == 3'h4 ? _nextLegalCASW_io_set_bits_T_7 :
    _nextLegalCASW_io_set_bits_T_9; // @[DramCommon.scala 499:44 DramCommon.scala 508:31]
  assign nextLegalCASW_targetFire = targetFire;
  assign tFAWcheck_clock = clock;
  assign tFAWcheck_reset = reset;
  assign tFAWcheck_io_enq_valid = io_cmdUsesThisRank & io_selectedCmd == 3'h1; // @[DramCommon.scala 490:48]
  assign tFAWcheck_io_enq_bits = io_tCycle + io_timings_tFAW; // @[DramCommon.scala 491:38]
  assign tFAWcheck_io_deq_ready = io_tCycle == tFAWcheck_io_deq_bits; // @[DramCommon.scala 492:39]
  assign tFAWcheck_targetFire = targetFire;
  assign BankStateTracker_clock = clock;
  assign BankStateTracker_reset = reset;
  assign BankStateTracker_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_io_cmdUsesThisBank = io_cmdBankOH[0] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_targetFire = targetFire;
  assign BankStateTracker_1_clock = clock;
  assign BankStateTracker_1_reset = reset;
  assign BankStateTracker_1_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_1_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_1_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_1_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_1_io_cmdUsesThisBank = io_cmdBankOH[1] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_1_targetFire = targetFire;
  assign BankStateTracker_2_clock = clock;
  assign BankStateTracker_2_reset = reset;
  assign BankStateTracker_2_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_2_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_2_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_2_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_2_io_cmdUsesThisBank = io_cmdBankOH[2] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_2_targetFire = targetFire;
  assign BankStateTracker_3_clock = clock;
  assign BankStateTracker_3_reset = reset;
  assign BankStateTracker_3_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_3_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_3_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_3_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_3_io_cmdUsesThisBank = io_cmdBankOH[3] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_3_targetFire = targetFire;
  assign BankStateTracker_4_clock = clock;
  assign BankStateTracker_4_reset = reset;
  assign BankStateTracker_4_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_4_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_4_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_4_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_4_io_cmdUsesThisBank = io_cmdBankOH[4] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_4_targetFire = targetFire;
  assign BankStateTracker_5_clock = clock;
  assign BankStateTracker_5_reset = reset;
  assign BankStateTracker_5_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_5_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_5_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_5_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_5_io_cmdUsesThisBank = io_cmdBankOH[5] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_5_targetFire = targetFire;
  assign BankStateTracker_6_clock = clock;
  assign BankStateTracker_6_reset = reset;
  assign BankStateTracker_6_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_6_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_6_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_6_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_6_io_cmdUsesThisBank = io_cmdBankOH[6] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_6_targetFire = targetFire;
  assign BankStateTracker_7_clock = clock;
  assign BankStateTracker_7_reset = reset;
  assign BankStateTracker_7_io_timings_tAL = io_timings_tAL; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tCWD = io_timings_tCWD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tCCD = io_timings_tCCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tRAS = io_timings_tRAS; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tRC = io_timings_tRC; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tRCD = io_timings_tRCD; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tRP = io_timings_tRP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tRTP = io_timings_tRTP; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_timings_tWR = io_timings_tWR; // @[DramCommon.scala 550:18]
  assign BankStateTracker_7_io_selectedCmd = io_selectedCmd; // @[DramCommon.scala 551:22]
  assign BankStateTracker_7_io_autoPRE = io_autoPRE; // @[DramCommon.scala 554:17]
  assign BankStateTracker_7_io_cmdRow = io_cmdRow; // @[DramCommon.scala 553:17]
  assign BankStateTracker_7_io_cmdUsesThisBank = io_cmdBankOH[7] & io_cmdUsesThisRank; // @[DramCommon.scala 552:45]
  assign BankStateTracker_7_targetFire = targetFire;
  always @(posedge clock) begin
    if (reset & targetFire) begin // @[DramCommon.scala 479:22]
      tREFI <= 14'h0; // @[DramCommon.scala 479:22]
    end else if (targetFire) begin
      if (tREFI == io_timings_tREFI & io_timings_tREFI != 14'h0) begin // @[DramCommon.scala 535:65]
        tREFI <= 14'h0; // @[DramCommon.scala 536:11]
      end else begin
        tREFI <= _tREFI_T_1; // @[DramCommon.scala 539:11]
      end
    end
    if (reset & targetFire) begin // @[DramCommon.scala 480:22]
      state <= 1'h0; // @[DramCommon.scala 480:22]
    end else if (targetFire) begin
      if (state & nextLegalACT_io_current == 10'h1) begin // @[DramCommon.scala 542:68]
        state <= 1'h0; // @[DramCommon.scala 543:11]
      end else if (!(_tFAWcheck_io_enq_valid_T_1)) begin // @[DramCommon.scala 494:59]
        state <= _GEN_19;
      end
    end
    if (reset & targetFire) begin // @[DramCommon.scala 481:24]
      wantREF <= 1'h0; // @[DramCommon.scala 481:24]
    end else if (targetFire) begin
      wantREF <= _GEN_30;
    end
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_tFAWcheck_io_enq_valid_T_1 & ~(io_rank_canACT | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Rank Timing Violation: Controller issued ACT command illegally\n    at DramCommon.scala:495 assert(io.rank.canACT, \"Rank Timing Violation: Controller issued ACT command illegally\")\n"
            ); // @[DramCommon.scala 495:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_tFAWcheck_io_enq_valid_T_1 & ~(io_rank_canACT | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 495:11]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (~_tFAWcheck_io_enq_valid_T_1 & _T_5 & ~(~io_cmdUsesThisRank | io_rank_canCASR | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Rank Timing Violation: Controller issued CASR command illegally\n    at DramCommon.scala:500 assert(!io.cmdUsesThisRank || io.rank.canCASR,\n"
            ); // @[DramCommon.scala 500:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (~_tFAWcheck_io_enq_valid_T_1 & _T_5 & ~(~io_cmdUsesThisRank | io_rank_canCASR | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 500:11]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_37 & ~_T_5 & _T_11 & ~(_T_6 | io_rank_canCASW | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Rank Timing Violation: Controller issued CASW command illegally\n    at DramCommon.scala:512 assert(!io.cmdUsesThisRank || io.rank.canCASW,\n"
            ); // @[DramCommon.scala 512:11]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_GEN_37 & ~_T_5 & _T_11 & ~(_T_6 | io_rank_canCASW | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 512:11]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_45 & ~_T_11 & _T_18 & ~(io_rank_canPRE | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Rank Timing Violation: Controller issued PRE command illegally\n    at DramCommon.scala:524 assert(io.rank.canPRE, \"Rank Timing Violation: Controller issued PRE command illegally\")\n"
            ); // @[DramCommon.scala 524:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_GEN_45 & ~_T_11 & _T_18 & ~(io_rank_canPRE | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 524:13]
        end
    `ifdef STOP_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef PRINTF_COND
      if (`PRINTF_COND) begin
    `endif
        if (_GEN_57 & ~_T_18 & _T_23 & ~(io_rank_canREF | reset) & targetFire) begin
          $fwrite(32'h80000002,
            "Assertion failed: Rank Timing Violation: Controller issued REF command illegally\n    at DramCommon.scala:527 assert(io.rank.canREF, \"Rank Timing Violation: Controller issued REF command illegally\")\n"
            ); // @[DramCommon.scala 527:13]
        end
    `ifdef PRINTF_COND
      end
    `endif
    `endif // SYNTHESIS
    `ifndef SYNTHESIS
    `ifdef STOP_COND
      if (`STOP_COND) begin
    `endif
        if (_GEN_57 & ~_T_18 & _T_23 & ~(io_rank_canREF | reset) & targetFire) begin
          $fatal; // @[DramCommon.scala 527:13]
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
  _RAND_0 = {1{`RANDOM}};
  tREFI = _RAND_0[13:0];
  _RAND_1 = {1{`RANDOM}};
  state = _RAND_1[0:0];
  _RAND_2 = {1{`RANDOM}};
  wantREF = _RAND_2[0:0];
`endif // RANDOMIZE_REG_INIT
  `endif // RANDOMIZE
end // initial
`ifdef FIRRTL_AFTER_INITIAL
`FIRRTL_AFTER_INITIAL
`endif
`endif // SYNTHESIS
endmodule