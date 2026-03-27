module alu_tb;
  import riscv_pkg::*;

  logic [XLEN-1:0] lhs;
  logic [XLEN-1:0] rhs;
  alu_op_t         op;
  logic [XLEN-1:0] dut_result;

  alu dut (
    .lhs_i     (lhs),
    .rhs_i     (rhs),
    .alu_op_i  (op),
    .result_o  (dut_result)
  );

  function automatic logic [XLEN-1:0] ref_alu(
    input logic [XLEN-1:0] a,
    input logic [XLEN-1:0] b,
    input alu_op_t         alu_op
  );
    logic signed [XLEN-1:0] as;
    logic signed [XLEN-1:0] bs;
    logic [4:0]             shamt;
    logic signed [63:0]     prod_ss;
    logic signed [63:0]     prod_su;
    logic [63:0]            prod_uu;
    begin
      as    = signed'(a);
      bs    = signed'(b);
      shamt = b[4:0];

      prod_ss = $signed(a) * $signed(b);
      prod_su = $signed(a) * $signed({1'b0, b}); // treat b as unsigned
      prod_uu = $unsigned(a) * $unsigned(b);

      unique case (alu_op)
        ALU_ADD:    ref_alu = a + b;
        ALU_SUB:    ref_alu = a - b;
        ALU_SLL:    ref_alu = a << shamt;
        ALU_SLT:    ref_alu = {{(XLEN-1){1'b0}}, (as < bs)};
        ALU_SLTU:   ref_alu = {{(XLEN-1){1'b0}}, (a < b)};
        ALU_XOR:    ref_alu = a ^ b;
        ALU_SRL:    ref_alu = a >> shamt;
        ALU_SRA:    ref_alu = logic'(as >>> shamt);
        ALU_OR:     ref_alu = a | b;
        ALU_AND:    ref_alu = a & b;
        ALU_COPY_B: ref_alu = b;

        ALU_MUL:    ref_alu = prod_ss[XLEN-1:0];
        ALU_MULH:   ref_alu = prod_ss[63:32];
        ALU_MULHSU: ref_alu = prod_su[63:32];
        ALU_MULHU:  ref_alu = prod_uu[63:32];

        ALU_DIV: begin
          if (b == '0) begin
            ref_alu = '1;
          end else if ((a == 32'h8000_0000) && (b == 32'hFFFF_FFFF)) begin
            ref_alu = a;
          end else begin
            ref_alu = logic'($signed(a) / $signed(b));
          end
        end

        ALU_DIVU: begin
          if (b == '0) begin
            ref_alu = '1;
          end else begin
            ref_alu = a / b;
          end
        end

        ALU_REM: begin
          if (b == '0) begin
            ref_alu = a;
          end else if ((a == 32'h8000_0000) && (b == 32'hFFFF_FFFF)) begin
            ref_alu = '0;
          end else begin
            ref_alu = logic'($signed(a) % $signed(b));
          end
        end

        ALU_REMU: begin
          if (b == '0) begin
            ref_alu = a;
          end else begin
            ref_alu = a % b;
          end
        end

        default: ref_alu = '0;
      endcase
    end
  endfunction

  task automatic check(
    input alu_op_t         alu_op,
    input logic [XLEN-1:0] a,
    input logic [XLEN-1:0] b
  );
    logic [XLEN-1:0] exp;
    begin
      lhs = a;
      rhs = b;
      op  = alu_op;
      #1ns;
      exp = ref_alu(a, b, alu_op);
      if (dut_result !== exp) begin
        $display("ALU mismatch op=%0d a=0x%08x b=0x%08x dut=0x%08x exp=0x%08x",
                 alu_op, a, b, dut_result, exp);
        $fatal(1);
      end
    end
  endtask

  initial begin
    lhs = '0;
    rhs = '0;
    op  = ALU_ADD;

    // Directed base-op tests
    check(ALU_ADD, 32'h0000_0001, 32'h0000_0001);
    check(ALU_SUB, 32'h0000_0000, 32'h0000_0001);
    check(ALU_SLL, 32'h0000_0001, 32'h0000_001F);
    check(ALU_SRL, 32'h8000_0000, 32'h0000_001F);
    check(ALU_SRA, 32'h8000_0000, 32'h0000_001F);
    check(ALU_SLT, 32'hFFFF_FFFF, 32'h0000_0001);
    check(ALU_SLTU, 32'hFFFF_FFFF, 32'h0000_0001);
    check(ALU_COPY_B, 32'h1234_5678, 32'hDEAD_BEEF);

    // M-extension directed corner cases
    check(ALU_DIV,  32'h0000_0007, 32'h0000_0000); // div by zero => -1
    check(ALU_DIVU, 32'h0000_0007, 32'h0000_0000); // divu by zero => all 1s
    check(ALU_REM,  32'h0000_0007, 32'h0000_0000); // rem by zero => dividend
    check(ALU_REMU, 32'h0000_0007, 32'h0000_0000); // remu by zero => dividend
    check(ALU_DIV,  32'h8000_0000, 32'hFFFF_FFFF); // overflow case
    check(ALU_REM,  32'h8000_0000, 32'hFFFF_FFFF); // overflow case remainder => 0

    // Randomized regression
    for (int i = 0; i < 2000; i++) begin
      logic [XLEN-1:0] a, b;
      a = $urandom();
      b = $urandom();

      check(ALU_ADD, a, b);
      check(ALU_SUB, a, b);
      check(ALU_SLL, a, b);
      check(ALU_SLT, a, b);
      check(ALU_SLTU, a, b);
      check(ALU_XOR, a, b);
      check(ALU_SRL, a, b);
      check(ALU_SRA, a, b);
      check(ALU_OR, a, b);
      check(ALU_AND, a, b);
      check(ALU_COPY_B, a, b);

      check(ALU_MUL, a, b);
      check(ALU_MULH, a, b);
      check(ALU_MULHSU, a, b);
      check(ALU_MULHU, a, b);
      check(ALU_DIV, a, b);
      check(ALU_DIVU, a, b);
      check(ALU_REM, a, b);
      check(ALU_REMU, a, b);
    end

    $display("ALU TB PASSED");
    $finish;
  end

endmodule : alu_tb

