`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:32:45 01/17/2017
// Design Name:   MVM_element
// Module Name:   D:/MVM research/verilog_code/matrix_vector_multiplication/MVM_element_test.v
// Project Name:  matrix_vector_multiplication
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: MVM_element
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module MVM_element_test;

	// Inputs
	reg [14:0] vector;
	reg [14:0] matrix_column;

	// Outputs
	wire [12:0] out;

	// Instantiate the Unit Under Test (UUT)
	MVM_element uut (
		.vector(vector), 
		.matrix_column(matrix_column), 
		.out(out)    
	);

	initial begin
		// Initialize Inputs


		// Wait 100 ns for global reset to finish
	
		vector = 15'b11111000100001100011;
		matrix_column = 15'b01001001111111000001;
        
		// Add stimulus here
    
	end    
      
endmodule

