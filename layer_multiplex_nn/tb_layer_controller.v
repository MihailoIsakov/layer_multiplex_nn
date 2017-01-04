`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:48:58 01/03/2017
// Design Name:   layer_controller
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_layer_controller.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: layer_controller
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_layer_controller;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [53:0] start_input;
	reg [59:0] layer_output;
	reg [5:0] layer_output_valid;

	// Outputs
	wire layer_start;
	wire [5:0] active;
	wire [53:0] layer_input;
	wire [611:0] layer_weights;

	// Instantiate the Unit Under Test (UUT)
	layer_controller uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.start_input(start_input), 
		.layer_output(layer_output), 
		.layer_output_valid(layer_output_valid), 
		.layer_start(layer_start), 
		.active(active), 
		.layer_input(layer_input), 
		.layer_weights(layer_weights)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		start_input = 0;
		layer_output = 0;
		layer_output_valid = 0;

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
            start_input  = 2345123455;
            layer_output = 1234123414;
            layer_output_valid = 6'b111111;
        #2  start = 0;

        #40 start_input  = 1234123455;
            layer_output = 1234123414;
            layer_output_valid = 6'b111110;
        
        #30 start_input  = 1234123452;
            layer_output = 1234123413;
            layer_output_valid = 6'b111010;

	end
      
endmodule

