package riscv_pkg;

  // RV32 base widths
  localparam int XLEN = 32;
  localparam int ILEN = 32;

  // ----------------------------------------------------------------------------
  // Primary opcode field values (inst[6:0]) for RV32IM
  // ----------------------------------------------------------------------------
  localparam logic [6:0] OPCODE_LUI      = 7'b0110111;
  localparam logic [6:0] OPCODE_AUIPC    = 7'b0010111;
  localparam logic [6:0] OPCODE_JAL      = 7'b1101111;
  localparam logic [6:0] OPCODE_JALR     = 7'b1100111;
  localparam logic [6:0] OPCODE_BRANCH   = 7'b1100011;
  localparam logic [6:0] OPCODE_LOAD     = 7'b0000011;
  localparam logic [6:0] OPCODE_STORE    = 7'b0100011;
  localparam logic [6:0] OPCODE_OP_IMM   = 7'b0010011;
  localparam logic [6:0] OPCODE_OP       = 7'b0110011;
  localparam logic [6:0] OPCODE_MISC_MEM = 7'b0001111; // FENCE/FENCE.I
  localparam logic [6:0] OPCODE_SYSTEM   = 7'b1110011;

  // M-extension shares OP opcode and uses funct7 = 7'b0000001.
  localparam logic [6:0] FUNCT7_M_EXT = 7'b0000001;

  // Common funct3 values
  localparam logic [2:0] F3_ADD_SUB  = 3'b000;
  localparam logic [2:0] F3_SLL      = 3'b001;
  localparam logic [2:0] F3_SLT      = 3'b010;
  localparam logic [2:0] F3_SLTU     = 3'b011;
  localparam logic [2:0] F3_XOR      = 3'b100;
  localparam logic [2:0] F3_SRL_SRA  = 3'b101;
  localparam logic [2:0] F3_OR       = 3'b110;
  localparam logic [2:0] F3_AND      = 3'b111;

  // Branch funct3 values
  localparam logic [2:0] F3_BEQ   = 3'b000;
  localparam logic [2:0] F3_BNE   = 3'b001;
  localparam logic [2:0] F3_BLT   = 3'b100;
  localparam logic [2:0] F3_BGE   = 3'b101;
  localparam logic [2:0] F3_BLTU  = 3'b110;
  localparam logic [2:0] F3_BGEU  = 3'b111;

  // Load funct3 values
  localparam logic [2:0] F3_LB   = 3'b000;
  localparam logic [2:0] F3_LH   = 3'b001;
  localparam logic [2:0] F3_LW   = 3'b010;
  localparam logic [2:0] F3_LBU  = 3'b100;
  localparam logic [2:0] F3_LHU  = 3'b101;

  // Store funct3 values
  localparam logic [2:0] F3_SB = 3'b000;
  localparam logic [2:0] F3_SH = 3'b001;
  localparam logic [2:0] F3_SW = 3'b010;

  // ALU operation encoding used between decode and execute.
  typedef enum logic [4:0] {
    ALU_ADD    = 5'd0,
    ALU_SUB    = 5'd1,
    ALU_SLL    = 5'd2,
    ALU_SLT    = 5'd3,
    ALU_SLTU   = 5'd4,
    ALU_XOR    = 5'd5,
    ALU_SRL    = 5'd6,
    ALU_SRA    = 5'd7,
    ALU_OR     = 5'd8,
    ALU_AND    = 5'd9,
    ALU_COPY_B = 5'd10, // e.g. for LUI
    ALU_MUL    = 5'd11,
    ALU_MULH   = 5'd12,
    ALU_MULHSU = 5'd13,
    ALU_MULHU  = 5'd14,
    ALU_DIV    = 5'd15,
    ALU_DIVU   = 5'd16,
    ALU_REM    = 5'd17,
    ALU_REMU   = 5'd18
  } alu_op_t;

  // Lightweight instruction field view.
  typedef struct packed {
    logic [6:0] opcode;
    logic [4:0] rd;
    logic [2:0] funct3;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [6:0] funct7;
  } inst_fields_t;

  // Forwarding mux select used for ALU operand bypassing.
  typedef enum logic [1:0] {
    FWD_FROM_RF     = 2'b00, // Register file output
    FWD_FROM_EX_MEM = 2'b01, // Result in EX/MEM stage
    FWD_FROM_MEM_WB = 2'b10  // Result in MEM/WB stage
  } fwd_sel_t;

  // IF/ID pipeline register bundle.
  typedef struct packed {
    logic              valid;
    logic [XLEN-1:0]   pc;
    logic [ILEN-1:0]   instr;
  } if_id_t;

  // ID/EX pipeline register bundle.
  typedef struct packed {
    logic              valid;
    logic [XLEN-1:0]   pc;
    logic [4:0]        rs1;
    logic [4:0]        rs2;
    logic [4:0]        rd;
    logic [XLEN-1:0]   rs1_data;
    logic [XLEN-1:0]   rs2_data;
    logic [XLEN-1:0]   imm;
    logic [2:0]        funct3;
    logic [6:0]        funct7;
    alu_op_t           alu_op;
    logic              use_imm;
    logic              branch;
    logic              jump;
    logic              mem_read;
    logic              mem_write;
    logic              wb_en;
    logic              wb_sel_mem;
  } id_ex_t;

  // EX/MEM pipeline register bundle.
  typedef struct packed {
    logic              valid;
    logic [XLEN-1:0]   pc;
    logic [4:0]        rd;
    logic [2:0]        funct3;
    logic [XLEN-1:0]   alu_result;
    logic [XLEN-1:0]   store_data;
    logic              branch_taken;
    logic [XLEN-1:0]   branch_target;
    logic              mem_read;
    logic              mem_write;
    logic              wb_en;
    logic              wb_sel_mem;
  } ex_mem_t;

  // MEM/WB pipeline register bundle.
  typedef struct packed {
    logic              valid;
    logic [4:0]        rd;
    logic [XLEN-1:0]   alu_result;
    logic [XLEN-1:0]   mem_rdata;
    logic              wb_en;
    logic              wb_sel_mem;
  } mem_wb_t;

endpackage : riscv_pkg
