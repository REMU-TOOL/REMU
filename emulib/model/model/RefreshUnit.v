module RefreshUnit(
  input        io_rankStati_0_canPRE,
  input        io_rankStati_0_canREF,
  input        io_rankStati_0_wantREF,
  input        io_rankStati_0_banks_0_canPRE,
  input        io_rankStati_0_banks_1_canPRE,
  input        io_rankStati_0_banks_2_canPRE,
  input        io_rankStati_0_banks_3_canPRE,
  input        io_rankStati_0_banks_4_canPRE,
  input        io_rankStati_0_banks_5_canPRE,
  input        io_rankStati_0_banks_6_canPRE,
  input        io_rankStati_0_banks_7_canPRE,
  input        io_rankStati_1_canPRE,
  input        io_rankStati_1_canREF,
  input        io_rankStati_1_wantREF,
  input        io_rankStati_1_banks_0_canPRE,
  input        io_rankStati_1_banks_1_canPRE,
  input        io_rankStati_1_banks_2_canPRE,
  input        io_rankStati_1_banks_3_canPRE,
  input        io_rankStati_1_banks_4_canPRE,
  input        io_rankStati_1_banks_5_canPRE,
  input        io_rankStati_1_banks_6_canPRE,
  input        io_rankStati_1_banks_7_canPRE,
  input        io_rankStati_2_canPRE,
  input        io_rankStati_2_canREF,
  input        io_rankStati_2_wantREF,
  input        io_rankStati_2_banks_0_canPRE,
  input        io_rankStati_2_banks_1_canPRE,
  input        io_rankStati_2_banks_2_canPRE,
  input        io_rankStati_2_banks_3_canPRE,
  input        io_rankStati_2_banks_4_canPRE,
  input        io_rankStati_2_banks_5_canPRE,
  input        io_rankStati_2_banks_6_canPRE,
  input        io_rankStati_2_banks_7_canPRE,
  input        io_rankStati_3_canPRE,
  input        io_rankStati_3_canREF,
  input        io_rankStati_3_wantREF,
  input        io_rankStati_3_banks_0_canPRE,
  input        io_rankStati_3_banks_1_canPRE,
  input        io_rankStati_3_banks_2_canPRE,
  input        io_rankStati_3_banks_3_canPRE,
  input        io_rankStati_3_banks_4_canPRE,
  input        io_rankStati_3_banks_5_canPRE,
  input        io_rankStati_3_banks_6_canPRE,
  input        io_rankStati_3_banks_7_canPRE,
  input  [3:0] io_ranksInUse,
  output       io_suggestREF,
  output [1:0] io_refRankAddr,
  output       io_suggestPRE,
  output [1:0] io_preRankAddr,
  output [2:0] io_preBankAddr
);
  wire [3:0] ranksWantingRefresh = {io_rankStati_3_wantREF,io_rankStati_2_wantREF,io_rankStati_1_wantREF,
    io_rankStati_0_wantREF}; // @[DramCommon.scala 630:69]
  wire [3:0] _refreshableRanks_T = {io_rankStati_3_canREF,io_rankStati_2_canREF,io_rankStati_1_canREF,
    io_rankStati_0_canREF}; // @[DramCommon.scala 631:65]
  wire [3:0] refreshableRanks = _refreshableRanks_T & io_ranksInUse; // @[DramCommon.scala 631:72]
  wire [3:0] _io_refRankAddr_T = ranksWantingRefresh & refreshableRanks; // @[DramCommon.scala 633:57]
  wire [1:0] _io_refRankAddr_T_5 = _io_refRankAddr_T[2] ? 2'h2 : 2'h3; // @[Mux.scala 47:69]
  wire [1:0] _io_refRankAddr_T_6 = _io_refRankAddr_T[1] ? 2'h1 : _io_refRankAddr_T_5; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T = io_rankStati_0_banks_6_canPRE ? 3'h6 : 3'h7; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_1 = io_rankStati_0_banks_5_canPRE ? 3'h5 : _preRefBanks_T; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_2 = io_rankStati_0_banks_4_canPRE ? 3'h4 : _preRefBanks_T_1; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_3 = io_rankStati_0_banks_3_canPRE ? 3'h3 : _preRefBanks_T_2; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_4 = io_rankStati_0_banks_2_canPRE ? 3'h2 : _preRefBanks_T_3; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_5 = io_rankStati_0_banks_1_canPRE ? 3'h1 : _preRefBanks_T_4; // @[Mux.scala 47:69]
  wire [2:0] preRefBanks_0 = io_rankStati_0_banks_0_canPRE ? 3'h0 : _preRefBanks_T_5; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_6 = io_rankStati_1_banks_6_canPRE ? 3'h6 : 3'h7; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_7 = io_rankStati_1_banks_5_canPRE ? 3'h5 : _preRefBanks_T_6; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_8 = io_rankStati_1_banks_4_canPRE ? 3'h4 : _preRefBanks_T_7; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_9 = io_rankStati_1_banks_3_canPRE ? 3'h3 : _preRefBanks_T_8; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_10 = io_rankStati_1_banks_2_canPRE ? 3'h2 : _preRefBanks_T_9; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_11 = io_rankStati_1_banks_1_canPRE ? 3'h1 : _preRefBanks_T_10; // @[Mux.scala 47:69]
  wire [2:0] preRefBanks_1 = io_rankStati_1_banks_0_canPRE ? 3'h0 : _preRefBanks_T_11; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_12 = io_rankStati_2_banks_6_canPRE ? 3'h6 : 3'h7; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_13 = io_rankStati_2_banks_5_canPRE ? 3'h5 : _preRefBanks_T_12; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_14 = io_rankStati_2_banks_4_canPRE ? 3'h4 : _preRefBanks_T_13; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_15 = io_rankStati_2_banks_3_canPRE ? 3'h3 : _preRefBanks_T_14; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_16 = io_rankStati_2_banks_2_canPRE ? 3'h2 : _preRefBanks_T_15; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_17 = io_rankStati_2_banks_1_canPRE ? 3'h1 : _preRefBanks_T_16; // @[Mux.scala 47:69]
  wire [2:0] preRefBanks_2 = io_rankStati_2_banks_0_canPRE ? 3'h0 : _preRefBanks_T_17; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_18 = io_rankStati_3_banks_6_canPRE ? 3'h6 : 3'h7; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_19 = io_rankStati_3_banks_5_canPRE ? 3'h5 : _preRefBanks_T_18; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_20 = io_rankStati_3_banks_4_canPRE ? 3'h4 : _preRefBanks_T_19; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_21 = io_rankStati_3_banks_3_canPRE ? 3'h3 : _preRefBanks_T_20; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_22 = io_rankStati_3_banks_2_canPRE ? 3'h2 : _preRefBanks_T_21; // @[Mux.scala 47:69]
  wire [2:0] _preRefBanks_T_23 = io_rankStati_3_banks_1_canPRE ? 3'h1 : _preRefBanks_T_22; // @[Mux.scala 47:69]
  wire [2:0] preRefBanks_3 = io_rankStati_3_banks_0_canPRE ? 3'h0 : _preRefBanks_T_23; // @[Mux.scala 47:69]
  wire  _prechargeableRanks_T_6 = io_rankStati_0_banks_0_canPRE | io_rankStati_0_banks_1_canPRE |
    io_rankStati_0_banks_2_canPRE | io_rankStati_0_banks_3_canPRE | io_rankStati_0_banks_4_canPRE |
    io_rankStati_0_banks_5_canPRE | io_rankStati_0_banks_6_canPRE | io_rankStati_0_banks_7_canPRE; // @[DramCommon.scala 640:45]
  wire  _prechargeableRanks_T_7 = io_rankStati_0_canPRE & _prechargeableRanks_T_6; // @[DramCommon.scala 639:75]
  wire  _prechargeableRanks_T_14 = io_rankStati_1_banks_0_canPRE | io_rankStati_1_banks_1_canPRE |
    io_rankStati_1_banks_2_canPRE | io_rankStati_1_banks_3_canPRE | io_rankStati_1_banks_4_canPRE |
    io_rankStati_1_banks_5_canPRE | io_rankStati_1_banks_6_canPRE | io_rankStati_1_banks_7_canPRE; // @[DramCommon.scala 640:45]
  wire  _prechargeableRanks_T_15 = io_rankStati_1_canPRE & _prechargeableRanks_T_14; // @[DramCommon.scala 639:75]
  wire  _prechargeableRanks_T_22 = io_rankStati_2_banks_0_canPRE | io_rankStati_2_banks_1_canPRE |
    io_rankStati_2_banks_2_canPRE | io_rankStati_2_banks_3_canPRE | io_rankStati_2_banks_4_canPRE |
    io_rankStati_2_banks_5_canPRE | io_rankStati_2_banks_6_canPRE | io_rankStati_2_banks_7_canPRE; // @[DramCommon.scala 640:45]
  wire  _prechargeableRanks_T_23 = io_rankStati_2_canPRE & _prechargeableRanks_T_22; // @[DramCommon.scala 639:75]
  wire  _prechargeableRanks_T_30 = io_rankStati_3_banks_0_canPRE | io_rankStati_3_banks_1_canPRE |
    io_rankStati_3_banks_2_canPRE | io_rankStati_3_banks_3_canPRE | io_rankStati_3_banks_4_canPRE |
    io_rankStati_3_banks_5_canPRE | io_rankStati_3_banks_6_canPRE | io_rankStati_3_banks_7_canPRE; // @[DramCommon.scala 640:45]
  wire  _prechargeableRanks_T_31 = io_rankStati_3_canPRE & _prechargeableRanks_T_30; // @[DramCommon.scala 639:75]
  wire [3:0] _prechargeableRanks_T_32 = {_prechargeableRanks_T_31,_prechargeableRanks_T_23,_prechargeableRanks_T_15,
    _prechargeableRanks_T_7}; // @[DramCommon.scala 640:55]
  wire [3:0] prechargeableRanks = _prechargeableRanks_T_32 & io_ranksInUse; // @[DramCommon.scala 640:62]
  wire [3:0] _io_suggestPRE_T = ranksWantingRefresh & prechargeableRanks; // @[DramCommon.scala 642:41]
  wire [1:0] _io_preRankAddr_T_5 = _io_suggestPRE_T[2] ? 2'h2 : 2'h3; // @[Mux.scala 47:69]
  wire [1:0] _io_preRankAddr_T_6 = _io_suggestPRE_T[1] ? 2'h1 : _io_preRankAddr_T_5; // @[Mux.scala 47:69]
  wire [2:0] _io_preBankAddr_T_5 = _io_suggestPRE_T[2] ? preRefBanks_2 : preRefBanks_3; // @[Mux.scala 47:69]
  wire [2:0] _io_preBankAddr_T_6 = _io_suggestPRE_T[1] ? preRefBanks_1 : _io_preBankAddr_T_5; // @[Mux.scala 47:69]
  assign io_suggestREF = |_io_refRankAddr_T; // @[DramCommon.scala 634:61]
  assign io_refRankAddr = _io_refRankAddr_T[0] ? 2'h0 : _io_refRankAddr_T_6; // @[Mux.scala 47:69]
  assign io_suggestPRE = |_io_suggestPRE_T; // @[DramCommon.scala 642:63]
  assign io_preRankAddr = _io_suggestPRE_T[0] ? 2'h0 : _io_preRankAddr_T_6; // @[Mux.scala 47:69]
  assign io_preBankAddr = _io_suggestPRE_T[0] ? preRefBanks_0 : _io_preBankAddr_T_6; // @[Mux.scala 47:69]
endmodule