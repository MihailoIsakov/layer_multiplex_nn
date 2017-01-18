`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:56:44 01/17/2017
// Design Name:   weight_controller
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_weight_controller.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: weight_controller
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_weight_controller;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [49:0] z;
	reg [44:0] delta;
	reg [1:0] layer;

	// Outputs
	wire [399:0] weights;

	// Instantiate the Unit Under Test (UUT)
	weight_controller uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.z(z), 
		.delta(delta), 
		.layer(layer), 
		.weights(weights)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		layer = 0;
		z = {10'd900, 10'd800, 10'd700, 10'd600, 10'd500}; // 10, 20, 30, 40, 50
		delta = {9'd1,  9'd2,  9'd3,  9'd4,  9'd5};  // 5,  4,  3,  2,  1

        #20 rst = 1;
        #2  rst = 0;

        #20 start = 1;
        #2  start = 0;


	end
      
endmodule

