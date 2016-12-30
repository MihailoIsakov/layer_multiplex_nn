`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   14:41:34 12/29/2016
// Design Name:   adder
// Module Name:   C:/Users/shiva/Desktop/research/fpu_adder/adder_test.v
// Project Name:  fpu_adder
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: adder
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module adder_test;

	// Inputs
	reg [31:0] input_a;
	reg [31:0] input_b;
	reg input_a_stb;
	reg input_b_stb;
	reg clk;
	reg rst;

	// Outputs
	wire [31:0] output_z;
	wire output_z_stb;

	// Instantiate the Unit Under Test (UUT)
	adder uut (
		.input_a(input_a), 
		.input_b(input_b), 
		.input_a_stb(input_a_stb), 
		.input_b_stb(input_b_stb), 
		.clk(clk), 
		.rst(rst), 
		.output_z(output_z), 
		.output_z_stb(output_z_stb)
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
		#20 input_a_stb = 1'b1 ;input_b_stb = 1'b1;input_a= 32'b01000001110010000000000000000000;input_b =32'b01000001011100000000000000000000;
		#20 input_a_stb = 1'b0 ;input_b_stb = 1'b1;
		#20 input_b_stb = 1'b0;

	end
      
endmodule

