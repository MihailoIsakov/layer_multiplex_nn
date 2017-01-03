`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:51:25 01/02/2017
// Design Name:   input_aggregator
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_input_aggregator.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: input_aggregator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_input_aggregator;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [53:0] start_input;
	reg [53:0] layer_input;
	reg layer_input_valid;

	// Outputs
	wire [1:0] layer_num;
	wire [53:0] out_inputs;
	wire [611:0] out_weights;
	wire layer_start;

	// Instantiate the Unit Under Test (UUT)
	input_aggregator uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.start_input(start_input), 
		.layer_input(layer_input), 
		.layer_input_valid(layer_input_valid), 
		.layer_num(layer_num), 
		.out_inputs(out_inputs), 
		.out_weights(out_weights), 
		.layer_start(layer_start)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		start_input = 123456789;
		layer_input = 987654321;
		layer_input_valid = 0;

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
        #2  start = 0;

        #20 layer_input_valid = 1;
        #2 layer_input_valid = 0;

        #30 layer_input_valid = 1;
        #2 layer_input_valid = 0;

        #10 layer_input_valid = 1;
        #2 layer_input_valid = 0;

        #20 layer_input_valid = 1;
        #2 layer_input_valid = 0;

	end
      
endmodule

