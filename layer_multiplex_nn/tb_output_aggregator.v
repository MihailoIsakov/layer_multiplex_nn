`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:26:40 01/03/2017
// Design Name:   output_aggregator
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_output_aggregator.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: output_aggregator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_output_aggregator;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [59:0] inputs_values;
	reg [5:0] inputs_valid;

	// Outputs
	wire [5:0] outputs_valid;
	wire [47:0] outputs;

	// Instantiate the Unit Under Test (UUT)
	output_aggregator uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.inputs_values(inputs_values), 
		.inputs_valid(inputs_valid), 
		.outputs_valid(outputs_valid), 
		.outputs_values(outputs)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		inputs_values = {10'd0, 10'd200, 10'd400, 10'd600, 10'd800, 10'd1023};
		inputs_valid = 6'b010101;

        #20 rst = 1;
        #20 rst = 0;

        #40 inputs_values[ 9: 0] = 10'd100;
        #2  inputs_values[19:10] = 10'd300;
        #4  inputs_values[29:20] = 10'd500;
        #8  inputs_values[39:30] = 10'd700;
		    inputs_valid = 6'b000111;

        #31 inputs_values[49:40] = 10'd900;
        #31 inputs_values[59:50] = 10'd1000;

	end
      
endmodule

