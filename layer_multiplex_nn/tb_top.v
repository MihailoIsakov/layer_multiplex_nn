`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:13:48 01/04/2017
// Design Name:   top
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_top.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_top;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [53:0] start_input;

	// Outputs
	wire [53:0] final_output;
	wire [5:0] final_output_valid;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.start_input(start_input), 
		.final_output(final_output), 
		.final_output_valid(final_output_valid)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		start_input = 0;

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
            start_input = 125904376;
        #2  start = 0;

        #200 start = 1;
            start_input = 57602345;
        #2  start = 0;

	end
      
endmodule

