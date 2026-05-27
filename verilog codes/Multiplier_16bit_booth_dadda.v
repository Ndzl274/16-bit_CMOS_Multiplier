//This is a behavioral code for a 16 bit Booth-Dadda Multiplier
//There are three modules in this code 
//The 2 sub-module for handling Radix-4 encoding for a 3-bit window and will be instantiate 8 times and the full adder module
//The top-level module that takes in 16bit inputs and wires up the 8 Booth encoders

`timescale 1ns/ 1ps

//Stage 1: 3:2 Compressor (Full Adder)
module FA (
  input a, b, cin, 
  output sum, cout
);
    
assign sum = a ^ b ^ cin;
assign cout = (a & b) | (b & cin) | (a & cin);

endmodule

// Vectorised Carry-Save Adder (Row of 32 FAs)
// Compresses 3 rows into 2 rows (Sum and Carry)
module CSA_32 (
  input  [31:0] a,
  input  [31:0] b,
  input  [31:0] c,
  output [31:0] sum,
  output [31:0] carry
);
  wire [31:0] carry_out_wire;

  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : csa_gen
      FA fa_inst (
        .a(a[i]),
        .b(b[i]),
        .cin(c[i]),
        .sum(sum[i]),
        .cout(carry_out_wire[i]) 
      );
    end
  endgenerate

  // Hardwire the structural shift: Carry bits belong to the next highest column
  assign carry = {carry_out_wire[30:0], 1'b0};
endmodule

//Stage 2: Booth Radix-4 Encoder
module booth_encoding (
    input [2:0] m,       // 3-bit multiplier window
    input [15:0] y,      // Multiplicand
    output reg [31:0] pp // Partial Product
);
  always @(*) begin
    case (m)
      3'b000, 3'b111: pp = 32'd0;
      3'b001, 3'b010: pp = {{16{y[15]}}, y};                 // +1Y
      3'b011:         pp = {{15{y[15]}}, y, 1'b0};           // +2Y
      3'b100:         pp = ~({{15{y[15]}}, y, 1'b0}) + 1'b1; // -2Y
      3'b101, 3'b110: pp = ~({{16{y[15]}}, y}) + 1'b1;       // -1Y
      default:        pp = 32'd0;
    endcase
  end
  
endmodule

//Stage 3: 16 bit Booth Multiplier
module Multiplier_16bit (
  input CLK,
  input NRST,
  input EN,      // Enable signal for power-saving operand isolation
  input [15:0] a,
  input [15:0] b,
  output reg [31:0] c
);
  // 1. Input Registers for Operand Isolation (Power Saving)
  // Prevents the multiplier from toggling and burning dynamic power
  // when new data is not actively required.
  reg [15:0] a_reg;
  reg [15:0] b_reg;

  always @(posedge CLK or negedge NRST) begin
    if (!NRST) begin
      a_reg <= 16'h0;
      b_reg <= 16'h0;
    end else if (EN) begin
      a_reg <= a;
      b_reg <= b;
    end
  end

  // Internal signals
  wire [16:0] b_pad = {b_reg, 1'b0}; // Pad for Radix-4
  wire [31:0] pp [0:7];
  wire [31:0] s_pp [0:7];        //Shifted Partial Products
    
  // 1. Generate 8 Partial Products
  genvar i;
  generate
    for (i = 0; i < 8; i = i + 1) begin : gen_pp
      booth_encoding inst (
        .m(b_pad[2*i+2 : 2*i]),
        .y(a_reg),
        .pp(pp[i])
      );
      assign s_pp[i] = pp[i] << (2*i);
    end
  endgenerate

  // 2. Structural Dadda Reduction Tree
  //Dadda Stage 1: Reduce 8 rows to 6 rows
  wire [31:0] s1_sum, s1_carry;
  wire [31:0] s2_sum, s2_carry;
  
  CSA_32 csa1_1 (.a(s_pp[5]), .b(s_pp[6]), .c(s_pp[7]), .sum(s1_sum), .carry(s1_carry));
  CSA_32 csa1_2 (.a(s_pp[2]), .b(s_pp[3]), .c(s_pp[4]), .sum(s2_sum), .carry(s2_carry));
  // Current rows: s_pp[0], s_pp[1], s1_sum, s1_carry, s2_sum, s2_carry (Total: 6)
  
  // Dadda Stage 2: Reduce 6 rows to 4 rows
  wire [31:0] s3_sum, s3_carry;
  wire [31:0] s4_sum, s4_carry;
  
  CSA_32 csa2_1 (.a(s_pp[0]),  .b(s_pp[1]), .c(s1_sum),   .sum(s3_sum), .carry(s3_carry));
  CSA_32 csa2_2 (.a(s1_carry), .b(s2_sum),  .c(s2_carry), .sum(s4_sum), .carry(s4_carry));
  // Current rows: s3_sum, s3_carry, s4_sum, s4_carry (Total: 4)

  // Dadda Stage 3: Reduce 4 rows to 3 rows
  wire [31:0] s5_sum, s5_carry;
  
  CSA_32 csa3_1 (.a(s3_sum), .b(s3_carry), .c(s4_sum), .sum(s5_sum), .carry(s5_carry));
  // Current rows: s4_carry, s5_sum, s5_carry (Total: 3)

  // Dadda Stage 4: Reduce 3 rows to 2 rows
  wire [31:0] s6_sum, s6_carry;
  
  CSA_32 csa4_1 (.a(s4_carry), .b(s5_sum), .c(s5_carry), .sum(s6_sum), .carry(s6_carry));
  // Current rows: s6_sum, s6_carry (Total: 2)

  // 3. Final Stage: Carry Propagate Adder (CPA)
  wire [31:0] stage_sum;
  assign stage_sum = s6_sum + s6_carry;
  
  // 3. Registered Output
  always @(posedge CLK or negedge NRST) begin
    if (!NRST) begin
      c <= 32'h0;
    end else if (EN) begin
      c <= stage_sum;
    end
  end

endmodule