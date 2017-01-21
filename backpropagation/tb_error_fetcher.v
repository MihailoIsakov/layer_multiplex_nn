`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:49:59 01/19/2017
// Design Name:   error_fetcher
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_error_fetcher.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: error_fetcher
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_error_fetcher;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [1:0] layer;
	reg [9:0] sample_index;
	reg [49:0] z;
	reg [44:0] delta_input;
	reg delta_input_valid;

	// Outputs
	wire [44:0] delta_output;
	wire delta_output_valid;

	// Instantiate the Unit Under Test (UUT)
	error_fetcher uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.layer(layer), 
		.sample_index(sample_index), 
		.z(z), 
		.delta_input(delta_input), 
		.delta_input_valid(delta_input_valid), 
		.delta_output(delta_output), 
		.delta_output_valid(delta_output_valid)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		sample_index = 0;

		layer = 3;
		z = 0;
		delta_input = 0;
		delta_input_valid = 0;

        #20 rst = 1;
        #2  rst = 0;

        #20 start = 1;
            z           = {10'd1000, 10'd800, 10'd600, 10'd400, 10'd200}; // 10, 20, 30, 40, 50
            delta_input = {8'd1    , 8'd2   , 8'd3   , 8'd4   , 8'd5};  // 5   , 4 , 3 , 2 , 1
        #2  start = 0;

        #100 layer = 2;
            delta_input = {11'd0, 11'b11111111111, 11'd0, 11'b11111111111};
            delta_input_valid = 0;

        #20 delta_input_valid = 1;

	end
      
endmodule

