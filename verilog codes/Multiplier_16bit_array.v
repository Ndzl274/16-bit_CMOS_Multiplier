//This is a behavioral code for a 16bit array multiplier
//There are three modules in this code
//The Full Adder module, the 16-bit Ripple Carry Adder module and the top-level module that takes in the 16-bit input and multiplication occurs


`timescale 1ns/ 1ps

//Module 1: Full Adder
module fa (
    input wire a,
    input wire b,
    input wire cin,
    output wire sum,
    output wire cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (a & cin);
    
endmodule

// Module 2: 16-bit Ripple Carry Adder
module rca_16bit (
    input wire [15:0] a,
    input wire [15:0] b,
    output wire [15:0] sum,
    output wire cout
);
    wire [16:0] c;
    assign c[0] = 1'b0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_fa
            fa fa_inst (
                .a(a[i]),
                .b(b[i]),
                .cin(c[i]),
                .sum(sum[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

    assign cout = c[16];
    
endmodule

// Module 3: Top-Level Array Multiplier
module Multiplier_16bit (
    input wire CLK,
    input wire NRST,
    input wire EN,
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [31:0] c
);

    // 1. Generate Partial Products using AND gates
    wire [15:0] pp [0:15];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_pp
            assign pp[i] = a & {16{b[i]}};
        end
    endgenerate

    // 2. Structural Array Wiring
    wire [15:0] row_sum [0:15];
    wire row_cout [0:15];

    // The first row's sum is simply the first partial product
    assign row_sum[0] = pp[0];
    assign row_cout[0] = 1'b0;

    // Instantiate 15 Ripple Carry Adders to sum the rows
    genvar j;
    generate
        for (j = 1; j < 16; j = j + 1) begin : gen_rca
            // Shift the sum of the previous row right by 1 bit and pull in the carry
            wire [15:0] shifted_prev_sum = {row_cout[j-1], row_sum[j-1][15:1]};

            rca_16bit adder_row (
                .a(pp[j]),
                .b(shifted_prev_sum),
                .sum(row_sum[j]),
                .cout(row_cout[j])
            );
        end
    endgenerate

    // 3. Assemble the Final Combinational Result
    wire [31:0] comb_result;
    genvar k;
    generate
        // The lower 16 bits drop straight down from the LSB of each row
        for (k = 0; k < 16; k = k + 1) begin : assign_lower
            assign comb_result[k] = row_sum[k][0];
        end
    endgenerate
    
    // The upper 16 bits consist of the final row's shifted sum and carry out
    assign comb_result[31:16] = {row_cout[15], row_sum[15][15:1]};

    // 4. Synchronous Output Register
    always @(posedge CLK or negedge NRST) begin
        if (!NRST) begin
            c <= 32'h0;
        end else if (EN) begin
            c <= comb_result;
        end
    end

endmodule
