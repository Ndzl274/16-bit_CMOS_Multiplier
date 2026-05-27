// The code is a test benchmark for a 16bit multiplier
// The code is for UROP Project

`timescale 1ns / 1ps

module Multiplier_16bit_tb;
  reg CLK;
  reg NRST;
  reg [15:0] a;
  reg [15:0] b;
  wire [31:0] c;
  
  reg [31:0] test [0:15];
  integer i;
  
  initial $sdf_annotate("Syn_Multiplier_16bit.sdf",U1);
  
  Multiplier_16bit U1 (
     .CLK(CLK), .NRST(NRST), .a(a), .b(b), .c(c)
  );
  
  //Clock Generation
  initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
  end
  
  initial begin
    // For viewing in your waveform viewer (like DVE)
    $dumpfile("matrix_sim.vcd");
    $dumpvars(0, Multiplier_16bit_tb);

    // Initialise signals
    NRST  = 0;
    a = 0;
    b = 0;
    
    $vcdpluson(U1);
    $readmemh("InputVector.txt", test);

    // Apply Reset
    #20 NRST = 1; 

    for (i=0; i< 7; i = i +1) begin
      @(posedge CLK);
      {a,b} = test[i];
      $display ("Time: %0t | %0d:  %h * %h", $time, i, a, b);
    end

    $vcdplusoff(U1);
    $finish;
  end

endmodule