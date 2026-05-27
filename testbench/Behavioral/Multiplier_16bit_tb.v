// The code is a test benchmark for a 16bit multiplier
// The code is for UROP Project

`timescale 1ns/ 1ps
module Multiplier_16bit_tb;
  reg CLK;
  reg NRST;
  reg EN;
  reg [15:0] a;
  reg [15:0] b;
  wire [31:0] c;
  
  reg [31:0] test [0:15];
  integer i;
  
  Multiplier_16bit U1 (
     .CLK(CLK), .NRST(NRST), .EN(EN), .a(a), .b(b), .c(c)
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
    EN = 0;
    a = 0;
    b = 0;
    
    $readmemh("InputVector.txt", test);

    // Apply Reset
    #20 NRST = 1; 
    
    #10 EN = 1;

    for (i=0; i< 7; i = i +1) begin
      @(posedge CLK);
      {a,b} = test[i];
      $display ("Time: %0t | %0d:  %h * %h", $time, i, a, b);
    end
    
    @(posedge CLK);
    EN = 0;       //Turn off the Multiplier
    a = 16'hFFFF;
    b = 16'hFFFF;
    
    #30;
    
    $finish;
  end

endmodule