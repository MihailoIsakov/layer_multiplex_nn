`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:38:15 04/15/2017
// Design Name:   counter
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_counter.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: counter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_counter;

	// Inputs
	reg clk;
	reg rst;
	reg count_ready;

	// Outputs
	wire [9:0] count;
	wire count_valid;

	// Instantiate the Unit Under Test (UUT)
	counter uut (
		.clk(clk), 
		.rst(rst), 
		.count(count), 
		.count_valid(count_valid), 
		.count_ready(count_ready)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		count_ready = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

