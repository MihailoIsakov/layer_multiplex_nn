`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:46:16 01/22/2017
// Design Name:   vector_mac
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_vector_mac.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vector_mac
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_vector_mac;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [39:0] a;
	reg [39:0] b;

	// Outputs
	wire [8+8+4-1:0] result;
	wire valid;

	// Instantiate the Unit Under Test (UUT)
	vector_mac uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.a(a), 
		.b(b), 
		.result(result), 
		.valid(valid)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		a = 0;
		b = 0;

        #20 rst = 1;
        #2  rst = 0;

        #20 start = 1;
            a = {8'd10, -8'd20, 8'd1, 8'd100, 8'd0};
            b = {8'd5,   8'd4,  8'd3, 8'd2,   8'd1};
        #2  start = 0;

	end
      
endmodule

