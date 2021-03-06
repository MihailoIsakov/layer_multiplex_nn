`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:14:50 01/03/2017
// Design Name:   input_aggregator
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_input_aggregator2.v
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

module tb_input_aggregator2;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [53:0] start_input;
	reg [53:0] layer_input;
	reg [5:0] layer_input_valid;

	// Outputs
    wire [5:0] active;
	wire [2:0] layer_num;
	wire [53:0] out_inputs;
	wire [611:0] out_weights;
	wire layer_start;

	// Instantiate the Unit Under Test (UUT)
	input_aggregator 
    #(.LAYER_SIZES({6'b101010, 6'b111010, 6'b111110, 6'b111111})) 
    uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.start_input(start_input), 
		.layer_input(layer_input), 
		.layer_input_valid(layer_input_valid), 
		.layer_num(layer_num), 
		.out_inputs(out_inputs), 
		.out_weights(out_weights), 
		.layer_start(layer_start),
        .active(active)
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

        #20 layer_input_valid = 6'b111111; // finshed layer 1
        #2 layer_input_valid = 0;

        #30 layer_input_valid = 6'b111110; // finshed layer 2
        #2 layer_input_valid = 0;

        #10 layer_input_valid = 6'b111000; // not finished yet
        #2 layer_input_valid = 0;

        #10 layer_input_valid = 6'b111010; // finshed layer 3
        #2 layer_input_valid = 0;

        #20 layer_input_valid = 6'b101010; // finshed layer 4 - last layer
        #2 layer_input_valid = 0;

        #20 layer_input_valid = 6'b001010; // testing if once in IDLE, the state should not change
        #2 layer_input_valid = 0;  // has to receive a new start from outside

	end
      
endmodule

