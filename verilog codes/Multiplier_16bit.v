// Version: Standard 16bit Multiplier
// The code is a behavioral code for a 16bit multiplier
// The code is for UROP Project
`timescale 1ns / 1ps
module Multiplier_16bit (
  input wire CLK, NRST, 
  input wire EN,
  input wire [15:0] a,
  input wire [15:0] b,
  output reg [31:0] c
);

  reg [15:0] a_reg, b_reg;
  
  always @(posedge CLK or negedge NRST) begin
    if (!NRST) begin
      a_reg <= 16'h0;
      b_reg <= 16'h0;
      c <= 32'h0;
    end else if (EN) begin
      a_reg <= a;
      b_reg <= b;
      c <= a_reg * b_reg;
    end
  end

endmodule
