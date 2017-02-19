`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:12:49 02/16/2017
// Design Name:   backpropagator
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_backpropagator.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: backpropagator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_backpropagator;

    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 0,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 3,  // number of layers in the network
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets.list",
              WEIGHT_INIT_FILE    = "weight_init.list";

	// Inputs
	reg clk;
	reg rst;
    reg                                               start;
    reg [LAYER_ADDR_WIDTH-1:0]                        current_layer;
    reg [SAMPLE_ADDR_SIZE-1:0]                        sample;
    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          z;
    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]          z_prev;
    
	// Outputs
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    wire                                               valid;
    wire                                               error;

	// Instantiate the Unit Under Test (UUT)
	backpropagator uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.current_layer(current_layer), 
		.sample(sample), 
		.z(z), 
		.z_prev(z_prev), 
		.weights(weights), 
		.valid(valid), 
		.error(error)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		current_layer = LAYER_MAX;
		sample = 0;
		z = {10'd300, 10'd400, 10'd500, 10'd600, 10'd700};
		z_prev = {10'd300, 10'd400, 10'd500, 10'd600, 10'd700};

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

