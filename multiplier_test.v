`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:07:31 12/26/2016
// Design Name:   multiplier
// Module Name:   C:/Users/shiva/Desktop/research/Neuron_structure/multiplier_test.v
// Project Name:  Neuron_structure
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: multiplier
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module multiplier_test;

	// Inputs
	reg [7:0] input_a;
	reg input_a_stb;
	reg [7:0] input_b;
	reg input_b_stb;
	reg clk;
	reg rst;

	// Outputs
	wire [7:0] output_z;
	wire output_z_stb;

	// Instantiate the Unit Under Test (UUT)
	multiplier uut (
		.input_a(input_a), 
		.input_a_stb(input_a_stb), 
		.input_b(input_b), 
		.input_b_stb(input_b_stb), 
		.output_z(output_z), 
		.output_z_stb(output_z_stb), 
		.clk(clk), 
		.rst(rst)
	);
always
begin
#10 clk = 0;
#10 clk = 1;
end

	initial begin
		// Initialize Inputs
		input_a = 0;
		input_a_stb = 0;
		input_b = 0;
		input_b_stb = 0;  
		clk = 0;
		rst = 0;
		#20 rst = 1'b1;
		#20 rst = 0;
		#20 input_a_stb = 1'b1 ;input_b_stb = 1'b1;input_a= 8'b11010110;input_b =8'b00101001 ;
		#20 input_a_stb = 1'b1 ;input_b_stb = 1'b1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end   
      
endmodule

