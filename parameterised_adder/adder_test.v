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
	reg input_valid;
	reg clk;
	reg rst;

	// Outputs
	wire [31:0] output_z;
	wire output_valid;

	// Instantiate the Unit Under Test (UUT)
	adder uut (
		.input_a(input_a), 
		.input_b(input_b), 
		.input_valid(input_valid), 
		.output_z(output_z),
		.output_valid(output_valid),
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
		input_valid=0;
		input_b = 0;      
	            
		clk = 0;    
		rst = 0;     
		#20 rst = 1'b1;
		#20 rst = 0;
		#20 input_valid=1;input_a= 32'b00111111001000010100011110101110;input_b =32'b10111111010000000000000000000000;
      end
endmodule
