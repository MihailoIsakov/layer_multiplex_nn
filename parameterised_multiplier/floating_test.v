`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:08:46 01/04/2017
// Design Name:   decoder
// Module Name:   D:/fpga/floatingdecoder/floating_test.v
// Project Name:  floatingdecoder
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: decoder
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module floating_test;

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
	decoder uut (
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
		
	//two positive floating point numbers
	#20 input_valid = 1;input_a= 32'b00111111000000000000000000000000;input_b =32'b00111111000000000000000000000000;
	#20 input_valid = 0;
	
	
	//overflow checking
	#240 input_valid = 1;input_a= 32'b01111110110011010101110000101000;input_b =32'b01000011100000000000000000000000;
	#20 input_valid = 0;
	


	
  //one negative floating point numbers
	#240 input_valid = 1 ;input_a= 32'b11000001110011010101110000101000;input_b =32'b00111111000000000000000000000000;
	#20 input_valid = 0;
	   
		
 //underflow checking
	#240 input_valid = 1;input_a= 32'b00000001110011010101110000101000;input_b =32'b00000001000000000000000000000000;
	#20 input_valid = 0;
	
	
	end
	
	    
      
endmodule    


