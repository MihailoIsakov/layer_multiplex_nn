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

module tb_forward;

    parameter LAYER_MAX       = 3,
              NUM_NEURON      = 5,              // max number of neurons
              INPUT_SIZE      = 9,              // width of the input signals
              WEIGHT_SIZE     = 17,             // width of the weight signals
              ADDR_SIZE       = 10,
              INPUT_FRACTION  = 8,              // number of bits below the radix point in the input
              WEIGHT_FRACTION = 8,              // number of bits below the radix point in the weight
              FRACTION_BITS   = 6;              // for the output of OUTPUT_SIZE, FRACTION_BITS is the number of bits 

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [NUM_NEURON*INPUT_SIZE-1:0] start_input;
    reg [NUM_NEURON*NUM_NEURON*WEIGHT_SIZE-1:0] weights;
        //
	// Outputs
	wire [NUM_NEURON*INPUT_SIZE-1:0] final_output;
	wire final_output_valid;

    // Memories
    wire [9-1:0] output_mem [7-1:0];
    genvar i;
    generate
    for(i=0; i<7; i=i+1) begin: MEM
        assign output_mem[i] = final_output[i*9+:9];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	forward uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
        .weights(weights),
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

