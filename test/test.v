`timescale 1 ns / 1 ns

// Coprocessor 0 Registers

`define CP0_INDEX           8'b00000_000 // 0 , 0
`define CP0_RANDOM          8'b00001_000 // 1 , 0
`define CP0_ENTRYLO0        8'b00010_000 // 2 , 0
`define CP0_ENTRYLO1        8'b00011_000 // 3 , 0
`define CP0_CONTEXT         8'b00100_000 // 4 , 0
`define CP0_PAGEMASK        8'b00101_000 // 5 , 0
`define CP0_WIRED           8'b00110_000 // 6 , 0
`define CP0_BADVADDR        8'b01000_000 // 8 , 0
`define CP0_COUNT           8'b01001_000 // 9 , 0
`define CP0_ENTRYHI         8'b01010_000 // 10, 0
`define CP0_COMPARE         8'b01011_000 // 11, 0
`define CP0_STATUS          8'b01100_000 // 12, 0
`define CP0_CAUSE           8'b01101_000 // 13, 0
`define CP0_EPC             8'b01110_000 // 14, 0
`define CP0_PRID            8'b01111_000 // 15, 0
`define CP0_CONFIG          8'b10000_000 // 16, 0
`define CP0_CONFIG1         8'b10000_001 // 16, 1
`define CP0_TAGLO           8'b11100_000 // 28, 0

// TLB parameters
`define TLB_IDXBITS         5
`define TLB_ENTRIES         (1<<`TLB_IDXBITS)

// Coprocessor 0 Register Bits
// Index (0, 0)
`define INDEX_P             31
`define INDEX_INDEX         `TLB_IDXBITS-1:0

// Random (1, 0)
`define RANDOM_RANDOM       `TLB_IDXBITS-1:0

// EntryLo0, EntryLo1 (2 and 3, 0)
`define ENTRYLO_PFN         25:6
`define ENTRYLO_C           5:3
`define ENTRYLO_D           2
`define ENTRYLO_V           1
`define ENTRYLO_G           0

// Context (4, 0)
`define CONTEXT_PTEBASE     31:23
`define CONTEXT_BADVPN2     22:4

// PageMask (5, 0)
// Note: length of mask field is set to 12
`define PAGEMASK_MASK       24:13

// Wired (6, 0)
`define WIRED_WIRED         `TLB_IDXBITS-1:0

// EntryHi (10, 0)
`define ENTRYHI_VPN2        31:13
`define ENTRYHI_ASID        7:0

// Status (12, 0)
`define STATUS_CU0          28
`define STATUS_BEV          22
`define STATUS_IM           15:8
`define STATUS_UM           4
`define STATUS_EXL          1
`define STATUS_IE           0

// Cause (13, 0)
`define CAUSE_BD            31
`define CAUSE_TI            30
`define CAUSE_CE            29:28
`define CAUSE_IV            23
`define CAUSE_IP            15:8
`define CAUSE_IP7_2         15:10
`define CAUSE_IP1_0         9:8
`define CAUSE_EXCCODE       6:2

// Config (16, 0)
`define CONFIG_K0           2:0

// Exception vectors

`define VEC_RESET           32'hbfc0_0000
`define VEC_REFILL          32'h8000_0000
`define VEC_REFILL_EXL      32'h8000_0180
`define VEC_REFILL_BEV      32'hbfc0_0200
`define VEC_REFILL_BEV_EXL  32'hbfc0_0380
`define VEC_CACHEERR        32'ha000_0100
`define VEC_CACHEERR_BEV    32'dbfc0_0300
`define VEC_INTR            32'h8000_0180
`define VEC_INTR_IV         32'h8000_0200
`define VEC_INTR_BEV        32'hbfc0_0380
`define VEC_INTR_BEV_IV     32'hbfc0_0400
`define VEC_OTHER           32'h8000_0180
`define VEC_OTHER_BEV       32'hbfc0_0380

// EXCCODE

`define EXC_INT         5'h00
`define EXC_MOD         5'h01
`define EXC_TLBL        5'h02
`define EXC_TLBS        5'h03
`define EXC_ADEL        5'h04
`define EXC_ADES        5'h05
`define EXC_IBE         5'h06
`define EXC_DBE         5'h07
`define EXC_SYS         5'h08
`define EXC_BP          5'h09
`define EXC_RI          5'h0a
`define EXC_CPU         5'h0b
`define EXC_OV          5'h0c
`define EXC_TR          5'h0d

`define EXC_WATCH       5'h17

`define EXC_CACHEERR    5'h1e

// instruction encoding

`define GET_RS(x)       x[25:21]
`define GET_RT(x)       x[20:16]
`define GET_RD(x)       x[15:11]
`define GET_SA(x)       x[10:6]
`define GET_IMM(x)      x[15:0]
`define GET_INDEX(x) x[25:0]

// ALUop encoding

`define ALU_ADD   0
`define ALU_SUB   1
`define ALU_AND   2
`define ALU_OR    3
`define ALU_XOR   4
`define ALU_NOR   5
`define ALU_SLT   6
`define ALU_SLTU  7
`define ALU_SLL   8
`define ALU_SRL   9
`define ALU_SRA   10

// Control signal indexes

`define I_LB        0
`define I_LH        1
`define I_LWL       2
`define I_LW        3
`define I_LBU       4
`define I_LHU       5
`define I_LWR       6
`define I_SB        7
`define I_SH        8
`define I_SWL       9
`define I_SW        10
`define I_SWR       11

`define I_MEM_R     12
`define I_MEM_W     13
`define I_WEX       14
`define I_WWB       15

`define I_MAX       16

`define LDEC        106
`define LDECBITS    `LDEC-1:0

`define DECODED_OPS \
        op_sll,op_movft,op_srl,op_sra,op_sllv,op_srlv,op_srav, \
        op_jr,op_jalr,op_movz,op_movn,op_syscall,op_break,op_sync, \
        op_mfhi,op_mthi,op_mflo,op_mtlo,op_mult,op_multu,op_div,op_divu, \
        op_add,op_addu,op_sub,op_subu,op_and,op_or,op_xor,op_nor,op_slt,op_sltu, \
        op_tge,op_tgeu,op_tlt,op_tltu,op_teq,op_tne,op_bltz,op_bgez,op_bltzl,op_bgezl, \
        op_tgei,op_tgeiu,op_tlti,op_tltiu,op_teqi,op_tnei,op_bltzal,op_bgezal,op_bltzall,op_bgezall, \
        op_j,op_jal,op_beq,op_bne,op_blez,op_bgtz, \
        op_addi,op_addiu,op_slti,op_sltiu,op_andi,op_ori,op_xori,op_lui, \
        op_mfc0,op_mtc0,op_tlbr,op_tlbwi,op_tlbwr,op_tlbp,op_eret,op_wait,op_cop1, \
        op_beql,op_bnel,op_blezl,op_bgtzl, \
        op_madd,op_maddu,op_mul,op_msub,op_msubu,op_clz,op_clo, \
        op_lb,op_lh,op_lwl,op_lw,op_lbu,op_lhu,op_lwr,op_sb,op_sh,op_swl,op_sw,op_swr, \
        op_cache,op_ll,op_lwc1,op_pref,op_ldc1,op_sc,op_swc1,op_sdc1

// ALU module
module alu(
  input [31:0] A,
  input [31:0] B,
  input [10:0] ALUop,
  output Overflow,
  output CarryOut,
  output Zero,
  output [31:0] Result
);

  // ALUop decoder
  wire alu_add    = ALUop[`ALU_ADD];
  wire alu_sub    = ALUop[`ALU_SUB];
  wire alu_and    = ALUop[`ALU_AND];
  wire alu_or     = ALUop[`ALU_OR];
  wire alu_xor    = ALUop[`ALU_XOR];
  wire alu_nor    = ALUop[`ALU_NOR];
  wire alu_slt    = ALUop[`ALU_SLT];
  wire alu_sltu   = ALUop[`ALU_SLTU];
  wire alu_sll    = ALUop[`ALU_SLL];
  wire alu_srl    = ALUop[`ALU_SRL];
  wire alu_sra    = ALUop[`ALU_SRA];

  // invert B for subtractions (sub & slt)
  wire invb = alu_sub | alu_slt | alu_sltu;
  // select addend according to invb
  wire [31:0] addend = invb ? (~B) : B;

  // carryout flag for addition
  wire cf;
  // result for addition and subtraction
  wire [31:0] add_sub_res;
  // do addition (invb as carryin in subtraction)
  assign {cf, add_sub_res} = A + addend + invb;
  // calculate overflow flag
  wire of = A[31] ^ addend[31] ^ cf ^ add_sub_res[31];

  // do and operation
  wire [31:0] and_res = A & B;
  // do or operation
  wire [31:0] or_res = A | B;
  // do xor operation
  wire [31:0] xor_res = A ^ B;
  // do nor operation
  wire [31:0] nor_res = ~or_res;
  // set slt/sltu result according to subtraction result
  wire [31:0] slt_res = (add_sub_res[31] ^ of) ? 1 : 0;
  wire [31:0] sltu_res = (!cf) ? 1 : 0;
  // do sll operation
  wire [31:0] sll_res = B << A[4:0];
  // do srl&sra operation
  wire [64:0] sr_res_64 = {{32{alu_sra&B[31]}}, B} >> A[4:0];
  wire [31:0] sr_res = sr_res_64[31:0]; 

  // result muxer
  wire [31:0] res =
    {32{alu_and}} & and_res |
    {32{alu_or}} & or_res |
    {32{alu_xor}} & xor_res |
    {32{alu_nor}} & nor_res |
    {32{alu_add}} & add_sub_res |
    {32{alu_sub}} & add_sub_res |
    {32{alu_slt}} & slt_res |
    {32{alu_sltu}} & sltu_res |
    {32{alu_sll}} & sll_res |
    {32{alu_srl}} & sr_res |
    {32{alu_sra}} & sr_res;

  // set zero flag
  wire zf = (res == 0);

  // output results
  assign Overflow = of;
  assign CarryOut = cf ^ invb;
  assign Zero = zf;
  assign Result = res;
  
endmodule

// register file for MIPS 32

module reg_file(
	input clk,
	input [4:0] waddr,
	input [4:0] raddr1,
	input [4:0] raddr2,
	input wen,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);

  // registers (r0 excluded)
	reg [31:0] regs [31:1];

  // process read (r0 wired to 0)
	assign rdata1 = (raddr1 == 0 ? 0 : regs[raddr1]);
	assign rdata2 = (raddr2 == 0 ? 0 : regs[raddr2]);

  // process write
	always @(posedge clk) if (wen) regs[waddr] <= wdata;

endmodule

`define DATA_WIDTH 32

module shifter (
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [1:0] Shiftop,
	output [`DATA_WIDTH - 1:0] Result
);

	// TODO: Please add your logic code here
	wire sll;
	wire sra;
	wire srl;
	wire [`DATA_WIDTH - 1:0]sll_result;
	wire [`DATA_WIDTH - 1:0]sra_result;
	wire [`DATA_WIDTH - 1:0]srl_result;

	assign sll = Shiftop == 2'b00;
	assign sra = Shiftop == 2'b11;
	assign srl = Shiftop == 2'b10;
	assign sll_result = A << B[4:0];
	assign sra_result = ($signed(A)) >>> B[4:0];
	assign srl_result = A >> B[4:0];

	assign Result = ({`DATA_WIDTH{sll}} & sll_result)
				  | ({`DATA_WIDTH{sra}} & sra_result)
				  | ({`DATA_WIDTH{srl}} & srl_result);
	
endmodule

module decoder #(
    parameter integer bits = 4
)
(
    input [bits-1:0] in,
    output [(1<<bits)-1:0] out
);

  generate
    genvar i;
    for (i=0; i<(1<<bits); i=i+1) begin
      assign out[i] = in == i;
    end
  endgenerate

endmodule

module mips_cpu(
    input  rst,
    input  clk,

    output [31:0] PC,
    input  [31:0] Instruction,

    output [31:0] Address,
    output MemWrite,
    output [31:0] Write_data,
    output [3:0] Write_strb,

    input  [31:0] Read_data,
    output MemRead
);

    // THESE THREE SIGNALS ARE USED IN OUR TESTBENCH
    // PLEASE DO NOT MODIFY SIGNAL NAMES
    // AND PLEASE USE THEM TO CONNECT PORTS
    // OF YOUR INSTANTIATION OF THE REGISTER FILE MODULE
    wire			RF_wen;
    wire [4:0]		RF_waddr;
    wire [31:0]		RF_wdata;

    // TODO: PLEASE ADD YOUT CODE BELOW

    // IF

    wire branch;
    wire [31:0] branch_pc;
    reg [31:0] pc;
    wire [31:0] next_pc = pc + 32'd4;
    assign PC = pc;

    always @(posedge clk) begin
        if (rst) pc <= 32'd0;
        else if (branch) pc <= branch_pc;
        else pc <= next_pc;
    end

    // reg file

    wire [4:0] rf_raddr1, rf_raddr2, rf_waddr;
    wire [31:0] rf_rdata1, rf_rdata2, rf_wdata;
    wire rf_wen;
    reg_file rf(
       .clk         (clk),
       .waddr      (rf_waddr),
       .raddr1     (rf_raddr1),
       .raddr2     (rf_raddr2),
       .wen        (rf_wen),
       .wdata      (rf_wdata),
       .rdata1     (rf_rdata1),
       .rdata2     (rf_rdata2)
    );
    assign RF_wen = rf_wen;
    assign RF_waddr = rf_waddr;
    assign RF_wdata = rf_wdata;

    // ID

    wire [31:0] inst = Instruction;

    wire [63:0] op_d, func_d;
    wire [31:0] rs_d, rt_d, rd_d, sa_d;
    
    decoder #(.bits(6))
    dec_op (.in(inst[31:26]), .out(op_d)), dec_func (.in(inst[5:0]), .out(func_d));
    
    decoder #(.bits(5))
    dec_rs (.in(inst[25:21]), .out(rs_d)), dec_rt (.in(inst[20:16]), .out(rt_d)),
    dec_rd (.in(inst[15:11]), .out(rd_d)), dec_sa (.in(inst[10:6]), .out(sa_d));

    wire op_sll       = op_d[0] && rs_d[0] && func_d[0];
    wire op_movft     = op_d[0] && sa_d[0] && func_d[1];
    wire op_srl       = op_d[0] && rs_d[0] && func_d[2];
    wire op_sra       = op_d[0] && rs_d[0] && func_d[3];
    wire op_sllv      = op_d[0] && sa_d[0] && func_d[4];
    wire op_srlv      = op_d[0] && sa_d[0] && func_d[6];
    wire op_srav      = op_d[0] && sa_d[0] && func_d[7];
    wire op_jr        = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[8];
    wire op_jalr      = op_d[0] && rt_d[0] && sa_d[0] && func_d[9];
    wire op_movz      = op_d[0] && sa_d[0] && func_d[10];
    wire op_movn      = op_d[0] && sa_d[0] && func_d[11];
    wire op_syscall   = op_d[0] && func_d[12];
    wire op_break     = op_d[0] && func_d[13];
    wire op_sync      = op_d[0] && rs_d[0] && rt_d[0] && rd_d[0] && func_d[15];
    wire op_mfhi      = op_d[0] && rs_d[0] && rt_d[0] && sa_d[0] && func_d[16];
    wire op_mthi      = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[17];
    wire op_mflo      = op_d[0] && rs_d[0] && rt_d[0] && sa_d[0] && func_d[18];
    wire op_mtlo      = op_d[0] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[19];
    wire op_mult      = op_d[0] && rd_d[0] && sa_d[0] && func_d[24];
    wire op_multu     = op_d[0] && rd_d[0] && sa_d[0] && func_d[25];
    wire op_div       = op_d[0] && rd_d[0] && sa_d[0] && func_d[26];
    wire op_divu      = op_d[0] && rd_d[0] && sa_d[0] && func_d[27];
    wire op_add       = op_d[0] && sa_d[0] && func_d[32];
    wire op_addu      = op_d[0] && sa_d[0] && func_d[33];
    wire op_sub       = op_d[0] && sa_d[0] && func_d[34];
    wire op_subu      = op_d[0] && sa_d[0] && func_d[35];
    wire op_and       = op_d[0] && sa_d[0] && func_d[36];
    wire op_or        = op_d[0] && sa_d[0] && func_d[37];
    wire op_xor       = op_d[0] && sa_d[0] && func_d[38];
    wire op_nor       = op_d[0] && sa_d[0] && func_d[39];
    wire op_slt       = op_d[0] && sa_d[0] && func_d[42];
    wire op_sltu      = op_d[0] && sa_d[0] && func_d[43];
    wire op_tge       = op_d[0] && func_d[48];
    wire op_tgeu      = op_d[0] && func_d[49];
    wire op_tlt       = op_d[0] && func_d[50];
    wire op_tltu      = op_d[0] && func_d[51];
    wire op_teq       = op_d[0] && func_d[52];
    wire op_tne       = op_d[0] && func_d[54];
    wire op_bltz      = op_d[1] && rt_d[0];
    wire op_bgez      = op_d[1] && rt_d[1];
    wire op_tgei      = op_d[1] && rt_d[8];
    wire op_tgeiu     = op_d[1] && rt_d[9];
    wire op_tlti      = op_d[1] && rt_d[10];
    wire op_tltiu     = op_d[1] && rt_d[11];
    wire op_teqi      = op_d[1] && rt_d[12];
    wire op_tnei      = op_d[1] && rt_d[14];
    wire op_bltzl     = op_d[1] && rt_d[2];
    wire op_bgezl     = op_d[1] && rt_d[3];
    wire op_bltzal    = op_d[1] && rt_d[16];
    wire op_bgezal    = op_d[1] && rt_d[17];
    wire op_bltzall   = op_d[1] && rt_d[18];
    wire op_bgezall   = op_d[1] && rt_d[19];
    wire op_j         = op_d[2];
    wire op_jal       = op_d[3];
    wire op_beq       = op_d[4];
    wire op_bne       = op_d[5];
    wire op_blez      = op_d[6] && rt_d[0];
    wire op_bgtz      = op_d[7] && rt_d[0];
    wire op_addi      = op_d[8];
    wire op_addiu     = op_d[9];
    wire op_slti      = op_d[10];
    wire op_sltiu     = op_d[11];
    wire op_andi      = op_d[12];
    wire op_ori       = op_d[13];
    wire op_xori      = op_d[14];
    wire op_lui       = op_d[15];
    wire op_mfc0      = op_d[16] && rs_d[0] && sa_d[0] && inst[5:3] == 3'b000;
    wire op_mtc0      = op_d[16] && rs_d[4] && sa_d[0] && inst[5:3] == 3'b000;
    wire op_tlbr      = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[1];
    wire op_tlbwi     = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[2];
    wire op_tlbwr     = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[6];
    wire op_tlbp      = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[8];
    wire op_eret      = op_d[16] && rs_d[16] && rt_d[0] && rd_d[0] && sa_d[0] && func_d[24];
    wire op_wait      = op_d[16] && inst[25] && func_d[32];
    wire op_cop1      = op_d[17] && !rs_d[14]; // foooooooooooo
    wire op_beql      = op_d[20];
    wire op_bnel      = op_d[21];
    wire op_blezl     = op_d[22] && rt_d[0];
    wire op_bgtzl     = op_d[23] && rt_d[0];
    wire op_madd      = op_d[28] && rd_d[0] && sa_d[0] && func_d[0];
    wire op_maddu     = op_d[28] && rd_d[0] && sa_d[0] && func_d[1];
    wire op_mul       = op_d[28] && sa_d[0] && func_d[2];
    wire op_msub      = op_d[28] && rd_d[0] && sa_d[0] && func_d[4];
    wire op_msubu     = op_d[28] && rd_d[0] && sa_d[0] && func_d[5];
    wire op_clz       = op_d[28] && sa_d[0] && func_d[32];
    wire op_clo       = op_d[28] && sa_d[0] && func_d[33];
    wire op_lb        = op_d[32];
    wire op_lh        = op_d[33];
    wire op_lwl       = op_d[34];
    wire op_lw        = op_d[35];
    wire op_lbu       = op_d[36];
    wire op_lhu       = op_d[37];
    wire op_lwr       = op_d[38];
    wire op_sb        = op_d[40];
    wire op_sh        = op_d[41];
    wire op_swl       = op_d[42];
    wire op_sw        = op_d[43];
    wire op_swr       = op_d[46];
    wire op_cache     = op_d[47];
    wire op_ll        = op_d[48];
    wire op_lwc1      = op_d[49];
    wire op_pref      = op_d[51];
    wire op_ldc1      = op_d[53];
    wire op_sc        = op_d[56];
    wire op_swc1      = op_d[57];
    wire op_sdc1      = op_d[61];

    assign rf_raddr1 = `GET_RS(inst);
    assign rf_raddr2 = `GET_RT(inst);

    wire [15:0] imm = `GET_IMM(inst);
    
    wire [31:0] seq_pc = pc + 32'd4;
    wire [31:0] pc_branch = seq_pc + {{14{imm[15]}}, imm, 2'd0};
    wire [31:0] pc_jump = {seq_pc[31:28], `GET_INDEX(inst), 2'd0};

    // EX

    wire [31:0] rdata1_i = rf_rdata1, rdata2_i = rf_rdata2, inst_i = inst;

    wire [`I_MAX-1:0] ctrl_sig;

    // conditional move
    wire cond_move                = op_movz && rdata2_i == 32'd0 || op_movn && rdata2_i != 32'd0;
    // write data to [rt] generated in ex stage
    wire inst_rt_wex              = op_addi||op_addiu||op_slti||op_sltiu||op_andi||op_ori||op_xori||op_lui||op_mfc0||op_clz||op_clo||op_sc;
    // write data to [rt] generated in wb stage
    wire inst_rt_wwb              = ctrl_sig[`I_MEM_R];
    // write data to [rd] generated in ex stage
    wire inst_rd_wex              = op_sll||op_srl||op_sra||op_sllv||op_srlv||op_srav||op_jr||op_jalr||op_mfhi||op_mflo||
                                    op_add||op_addu||op_sub||op_subu||op_and||op_or||op_xor||op_nor||op_slt||op_sltu||op_mul||cond_move;
    // write data to [31] generated in ex stage
    wire inst_r31_wex             = op_bltzal||op_bgezal||op_bltzall||op_bgezall||op_jal;
    
    assign ctrl_sig[`I_LB]        = op_lb;
    assign ctrl_sig[`I_LH]        = op_lh;
    assign ctrl_sig[`I_LWL]       = op_lwl;
    assign ctrl_sig[`I_LW]        = op_lw||op_ll;
    assign ctrl_sig[`I_LBU]       = op_lbu;
    assign ctrl_sig[`I_LHU]       = op_lhu;
    assign ctrl_sig[`I_LWR]       = op_lwr;
    assign ctrl_sig[`I_SB]        = op_sb;
    assign ctrl_sig[`I_SH]        = op_sh;
    assign ctrl_sig[`I_SWL]       = op_swl;
    assign ctrl_sig[`I_SW]        = op_sw;
    assign ctrl_sig[`I_SWR]       = op_swr;
    
    // load instruction
    assign ctrl_sig[`I_MEM_R]     = op_lb||op_lh||op_lwl||op_lw||op_lbu||op_lhu||op_lwr||op_ll;
    // store instruction
    assign ctrl_sig[`I_MEM_W]     = op_sb||op_sh||op_swl||op_sw||op_swr||op_sc/*&&llbit*/;
    // write data generated in ex stage
    assign ctrl_sig[`I_WEX]       = inst_rt_wex||inst_rd_wex||inst_r31_wex;
    // write data generated in wb stage
    assign ctrl_sig[`I_WWB]       = inst_rt_wwb;
    // imm is sign-extended
    wire imm_is_sx  = !(op_andi||op_ori||op_xori);
    // alu operand a is sa
    wire alu_a_sa   = op_sll||op_srl||op_sra;
    // alu operand b is imm
    wire alu_b_imm  = op_addi||op_addiu||op_slti||op_sltiu||op_andi||op_ori||op_xori||ctrl_sig[`I_MEM_R]||ctrl_sig[`I_MEM_W];
    wire do_link    = op_jal||op_jalr||op_bgezal||op_bltzal||op_bgezall||op_bltzall;
    wire exc_on_of  = op_add || op_sub || op_addi;
    
    wire do_bne     = op_bne||op_bnel;
    wire do_beq     = op_beq||op_beql;
    wire do_bgez    = op_bgez||op_bgezl||op_bgezal||op_bgezall;
    wire do_blez    = op_blez||op_blezl;
    wire do_bgtz    = op_bgtz||op_bgtzl;
    wire do_bltz    = op_bltz||op_bltzl||op_bltzal||op_bltzall;
    wire do_j       = op_j||op_jal;
    wire do_jr      = op_jr||op_jalr;
    wire likely     = op_bltzl||op_bgezl||op_bltzall||op_bgezall||op_beql||op_bnel||op_blezl||op_bgtzl;
    
    wire [4:0] waddr = {5{inst_rt_wex||inst_rt_wwb}}    & `GET_RT(inst_i)
                     | {5{inst_rd_wex}}                 & `GET_RD(inst_i)
                     | {5{inst_r31_wex}}                & 5'd31;

    // imm extension
    wire [15:0] imm = `GET_IMM(inst_i);
    wire [31:0] imm_sx = {{16{imm[15]}}, imm};
    wire [31:0] imm_zx = {16'd0, imm};
    wire [31:0] imm_32 = imm_is_sx ? imm_sx : imm_zx;
    
    // ALU operation
    wire [10:0] alu_op;
    assign alu_op[`ALU_ADD]   = op_add||op_addu||op_addi||op_addiu;
    assign alu_op[`ALU_SUB]   = op_sub||op_subu;
    assign alu_op[`ALU_AND]   = op_and||op_andi;
    assign alu_op[`ALU_OR]    = op_or||op_ori;
    assign alu_op[`ALU_XOR]   = op_xor||op_xori;
    assign alu_op[`ALU_NOR]   = op_nor;
    assign alu_op[`ALU_SLT]   = op_slt||op_slti;
    assign alu_op[`ALU_SLTU]  = op_sltu||op_sltiu;
    assign alu_op[`ALU_SLL]   = op_sll||op_sllv;
    assign alu_op[`ALU_SRL]   = op_srl||op_srlv;
    assign alu_op[`ALU_SRA]   = op_sra||op_srav;
    
    // ALU module
    wire [31:0] alu_a, alu_b, alu_res_wire;
    wire alu_of;
    alu alu_instance(
        .A          (alu_a),
        .B          (alu_b),
        .ALUop      (alu_op),
        .CarryOut   (),
        .Overflow   (alu_of),
        .Zero       (),
        .Result     (alu_res_wire)
    );

    // select operand sources
    assign alu_a = alu_a_sa ? {27'd0, `GET_SA(inst_i)} : rdata1_i;
    assign alu_b = alu_b_imm ? imm_32 : rdata2_i;

    // branch test
    wire branch_taken   = (do_bne && (rdata1_i != rdata2_i))
                       || (do_beq && (rdata1_i == rdata2_i))
                       || (do_bgez && !rdata1_i[31])
                       || (do_blez && (rdata1_i[31] || rdata1_i == 32'd0))
                       || (do_bgtz && !(rdata1_i[31] || rdata1_i == 32'd0))
                       || (do_bltz && rdata1_i[31]);

    assign branch           = do_j||do_jr||branch_taken;

    wire [31:0] pc_b_i = pc_branch, pc_j_i = pc_jump;
    assign branch_pc    = {32{!(do_j||do_jr)}} & pc_b_i
                        | {32{do_jr}} & rdata1_i
                        | {32{do_j}} & pc_j_i;

    wire [31:0] eaddr = rdata1_i + imm_sx;
    wire [1:0] mem_byte_offset = eaddr[1:0];
    wire [1:0] mem_byte_offsetn = ~mem_byte_offset;

    wire mem_read = ctrl_sig[`I_MEM_R]; // && !mem_adel;
    wire mem_write = ctrl_sig[`I_MEM_W]; // && !mem_ades;

    // mem write mask
    wire [3:0] data_wstrb =
        {4{op_sw||op_sc}} & 4'b1111 |
        {4{op_sh}} & (4'b0011 << mem_byte_offset) |
        {4{op_sb}} & (4'b0001 << mem_byte_offset) |
        {4{op_swl}} & (4'b1111 >> mem_byte_offsetn) |
        {4{op_swr}} & (4'b1111 << mem_byte_offset);
    
    // mem write data
    wire [31:0] data_wdata =
        {32{op_sw||op_sc}} & rdata2_i |
        {32{op_sh}} & {rdata2_i[15:0], rdata2_i[15:0]} |
        {32{op_sb}} & {rdata2_i[7:0], rdata2_i[7:0], rdata2_i[7:0], rdata2_i[7:0]} |
        {32{op_swl}} & (rdata2_i >> (8 * mem_byte_offsetn)) |
        {32{op_swr}} & (rdata2_i << (8 * mem_byte_offset));

    wire [31:0] fwd_data = {32{op_lui}} & {imm, 16'd0}
                    | {32{do_link}} & (pc + 32'd8)
                    | {32{op_movz||op_movn}} & rdata1_i
                    | {32{!(op_mfhi||op_mflo||op_lui||do_link||op_mfc0||op_movz||op_movn||op_mul||op_sc)}} & alu_res_wire;

    assign Address = {eaddr[31:2], 2'd0};
    assign MemRead = mem_read;
    assign MemWrite = mem_write;
    assign Write_data = data_wdata;
    assign Write_strb = data_wstrb;

    // WB

    wire [`I_MAX-1:0] ctrl_i = ctrl_sig;

    wire [31:0] data_rdata = Read_data;
    // process length & extension for read
    wire [7:0] mem_rdata_b = data_rdata >> (8 * mem_byte_offset);
    wire [15:0] mem_rdata_h = data_rdata >> (8 * mem_byte_offset);
    wire [31:0] mem_rdata_b_sx, mem_rdata_b_zx, mem_rdata_h_sx, mem_rdata_h_zx;
    assign mem_rdata_b_sx = {{24{mem_rdata_b[7]}}, mem_rdata_b};
    assign mem_rdata_b_zx = {24'd0, mem_rdata_b};
    assign mem_rdata_h_sx = {{16{mem_rdata_h[15]}}, mem_rdata_h};
    assign mem_rdata_h_zx = {16'd0, mem_rdata_h};
    
    wire [31:0] mem_rdata_b_res =
    {32{ctrl_i[`I_LB]}} & mem_rdata_b_sx |
    {32{ctrl_i[`I_LBU]}} & mem_rdata_b_zx;
    
    wire [31:0] mem_rdata_h_res =
    {32{ctrl_i[`I_LH]}} & mem_rdata_h_sx |
    {32{ctrl_i[`I_LHU]}} & mem_rdata_h_zx;
    
    // mem read mask
    wire [31:0] mem_rmask =
    {32{ctrl_i[`I_LW]||ctrl_i[`I_LH]||ctrl_i[`I_LHU]||ctrl_i[`I_LB]||ctrl_i[`I_LBU]}} & 32'hffffffff |
    {32{ctrl_i[`I_LWL]}} & (32'hffffffff << (8 * mem_byte_offsetn)) |
    {32{ctrl_i[`I_LWR]}} & (32'hffffffff >> (8 * mem_byte_offset));
    // mem read data
    wire [31:0] memdata = rdata2_i & ~mem_rmask |
    {32{ctrl_i[`I_LW]}} & data_rdata |
    {32{ctrl_i[`I_LH]||ctrl_i[`I_LHU]}} & mem_rdata_h_res |
    {32{ctrl_i[`I_LB]||ctrl_i[`I_LBU]}} & mem_rdata_b_res |
    {32{ctrl_i[`I_LWL]}} & (data_rdata << (8 * mem_byte_offsetn)) |
    {32{ctrl_i[`I_LWR]}} & (data_rdata >> (8 * mem_byte_offset));

    assign rf_wen   = ctrl_i[`I_WEX]||ctrl_i[`I_WWB];
    assign rf_waddr = waddr;
    assign rf_wdata = ctrl_i[`I_MEM_R] ? memdata : fwd_data;

endmodule
