`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:34:14 01/21/2017
// Design Name:   MVM_top
// Module Name:   D:/MVM research/verilog_code/MVM_top/MVM_top_test.v
// Project Name:  MVM_top
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: MVM_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module MVM_top_test;

	// Inputs
	reg [14:0] vector;
	reg [44:0] matrix;

	// Outputs
	wire [38:0] out;

	// Instantiate the Unit Under Test (UUT)
	MVM_top uut (
		.vector(vector), 
		.matrix(matrix), 
		.out(out)
	);

	initial begin

        
	   vector = 15'b000100001100011;
		matrix = 45'b000100001111111001000101110101111100111110111;

	end  
      
endmodule

