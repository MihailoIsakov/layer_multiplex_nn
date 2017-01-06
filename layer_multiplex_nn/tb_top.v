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
	reg [63-1:0] start_input;

	// Outputs
	wire [63-1:0] final_output;
	wire [20-1:0] final_output_valid;

    wire [9-1:0] outputs [7-1:0];
    genvar i;
    generate
    for(i=0; i<7; i=i+1) begin: MEM
        assign outputs[i] = final_output[i*9+:9];
    end
    endgenerate

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
            // the first neuron should have the highest value
            start_input = 62'b010000010001011001000100011000000101000000000000000000011111111;
        #2  start = 0;

        #300
        #20 start = 1;
            // the second neuron should have the highest value
            start_input = 62'b010001100000111101001011110000011001000000000000000000011111111;
        #2  start = 0;

        #300
        #20 start = 1;
            // the third neuron should have the highest value
            start_input = 62'b010010111001001100010000010000101110000000000000000000011111111;
        #2  start = 0;


	end
      
endmodule

