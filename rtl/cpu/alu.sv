module alu
  import riscv_pkg::*;
(
  input  logic [XLEN-1:0] lhs_i,
  input  logic [XLEN-1:0] rhs_i,
  input  alu_op_t         alu_op_i,
  output logic [XLEN-1:0] result_o
);

  logic signed [XLEN-1:0] lhs_s;
  logic signed [XLEN-1:0] rhs_s;
  logic [4:0]             shamt;

  always_comb begin
    lhs_s = signed'(lhs_i);
    rhs_s = signed'(rhs_i);
    shamt = rhs_i[4:0];

    unique case (alu_op_i)
      ALU_ADD:    result_o = lhs_i + rhs_i;
      ALU_SUB:    result_o = lhs_i - rhs_i;
      ALU_SLL:    result_o = lhs_i << shamt;
      ALU_SLT:    result_o = {{(XLEN-1){1'b0}}, (lhs_s < rhs_s)};
      ALU_SLTU:   result_o = {{(XLEN-1){1'b0}}, (lhs_i < rhs_i)};
      ALU_XOR:    result_o = lhs_i ^ rhs_i;
      ALU_SRL:    result_o = lhs_i >> shamt;
      ALU_SRA:    result_o = logic'(lhs_s >>> shamt);
      ALU_OR:     result_o = lhs_i | rhs_i;
      ALU_AND:    result_o = lhs_i & rhs_i;
      ALU_COPY_B: result_o = rhs_i;

      ALU_MUL:    result_o = logic'($signed(lhs_i) * $signed(rhs_i));
      ALU_MULH:   result_o = logic'(($signed(lhs_i) * $signed(rhs_i)) >> XLEN);
      ALU_MULHSU: result_o = logic'(($signed(lhs_i) * $unsigned(rhs_i)) >> XLEN);
      ALU_MULHU:  result_o = logic'(($unsigned(lhs_i) * $unsigned(rhs_i)) >> XLEN);

      ALU_DIV: begin
        if (rhs_i == '0) begin
          result_o = '1;
        end else if ((lhs_i == 32'h8000_0000) && (rhs_i == 32'hFFFF_FFFF)) begin
          result_o = lhs_i; // Signed overflow case per RISC-V spec.
        end else begin
          result_o = logic'($signed(lhs_i) / $signed(rhs_i));
        end
      end

      ALU_DIVU: begin
        if (rhs_i == '0) begin
          result_o = '1;
        end else begin
          result_o = lhs_i / rhs_i;
        end
      end

      ALU_REM: begin
        if (rhs_i == '0) begin
          result_o = lhs_i;
        end else if ((lhs_i == 32'h8000_0000) && (rhs_i == 32'hFFFF_FFFF)) begin
          result_o = '0; // Signed overflow case per RISC-V spec.
        end else begin
          result_o = logic'($signed(lhs_i) % $signed(rhs_i));
        end
      end

      ALU_REMU: begin
        if (rhs_i == '0) begin
          result_o = lhs_i;
        end else begin
          result_o = lhs_i % rhs_i;
        end
      end

      default: result_o = '0;
    endcase
  end

endmodule : alu
