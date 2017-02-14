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

    parameter NEURON_NUM          = 5,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              LAYER_ADDR_WIDTH    = 2,
              FRACTION_WIDTH      = 0,
              WEIGHT_INIT_FILE    = "weight_init.list";

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z;
	reg [NEURON_NUM*DELTA_CELL_WIDTH-1:0] delta;
	reg [LAYER_ADDR_WIDTH-1:0] layer;

	// Outputs
	wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    wire valid;

    // Memories
    wire [WEIGHT_CELL_WIDTH-1:0] weights_mem [0:NEURON_NUM*NEURON_NUM-1];
    wire [NEURON_OUTPUT_WIDTH-1:0] z_mem [0:NEURON_NUM-1];
    wire [DELTA_CELL_WIDTH-1:0] delta_mem [0:NEURON_NUM-1];

    genvar i;
    generate 
    for (i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM
        assign weights_mem[i] = weights[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
    end
    for (i=0; i<NEURON_NUM; i=i+1) begin: MEM2
        assign z_mem[i] = z[i*NEURON_OUTPUT_WIDTH+:NEURON_OUTPUT_WIDTH];
        assign delta_mem[i] = delta[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
    weight_controller #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) uut (
		.clk    (clk    ),
		.rst    (rst    ),
		.start  (start  ),
		.z      (z      ),
		.delta  (delta  ),
		.layer  (layer  ),
		.w      (weights),
        .valid  (valid  )
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		layer = 0;
		z     = {10'd900, 10'd800, 10'd700, 10'd600, 10'd500}; // 10, 20, 30, 40, 50
		delta = {10'd1,   10'd2,   10'd3,   10'd4,   10'd5};  // 5,  4,  3,  2,  1

        #20 rst = 1;
        #2  rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

