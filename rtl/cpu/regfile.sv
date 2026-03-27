module regfile
  import riscv_pkg::*;
(
  input  logic           clk_i,
  input  logic           rst_ni,

  // Read port A
  input  logic [4:0]     raddr_a_i,
  output logic [XLEN-1:0] rdata_a_o,

  // Read port B
  input  logic [4:0]     raddr_b_i,
  output logic [XLEN-1:0] rdata_b_o,

  // Write port
  input  logic           we_i,
  input  logic [4:0]     waddr_i,
  input  logic [XLEN-1:0] wdata_i
);

  logic [XLEN-1:0] regs_q [31:0];

  // Write port: synchronous, x0 is hard-wired to zero
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      regs_q <= '{default: '0};
    end else begin
      if (we_i && (waddr_i != 5'd0)) begin
        regs_q[waddr_i] <= wdata_i;
      end
      // Ensure x0 remains zero even if inadvertently written
      regs_q[5'd0] <= '0;
    end
  end

  // Combinational read ports, x0 reads as zero
  always_comb begin
    if (raddr_a_i == 5'd0) begin
      rdata_a_o = '0;
    end else if (we_i && (waddr_i != 5'd0) && (waddr_i == raddr_a_i)) begin
      rdata_a_o = wdata_i;
    end else begin
      rdata_a_o = regs_q[raddr_a_i];
    end

    if (raddr_b_i == 5'd0) begin
      rdata_b_o = '0;
    end else if (we_i && (waddr_i != 5'd0) && (waddr_i == raddr_b_i)) begin
      rdata_b_o = wdata_i;
    end else begin
      rdata_b_o = regs_q[raddr_b_i];
    end
  end

endmodule : regfile

