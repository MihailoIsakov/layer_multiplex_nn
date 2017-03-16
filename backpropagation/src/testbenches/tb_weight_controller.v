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

    parameter NEURON_NUM          = 4,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              LEARNING_RATE_SHIFT = 6,
              LAYER_ADDR_WIDTH    = 2,
              FRACTION_WIDTH      = 0,
              WEIGHT_INIT_FILE    = "weights4x4.list";

	// Inputs
	reg clk;
	reg rst;
    
    // layer
	reg [LAYER_ADDR_WIDTH-1:0] layer;
    
    // z 
	reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z;
    reg                                      z_valid;
    wire                                     z_ready;
    
    // delta 
	reg [NEURON_NUM*DELTA_CELL_WIDTH-1:0] delta;
    reg                                   delta_valid;
    wire                                  delta_ready;

	// Outputs
	wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w;
    wire                                               w_valid;
    reg                                                w_ready;
    
    // overflow
    wire error;

    // memories
    wire [WEIGHT_CELL_WIDTH-1:0] weights_mem [0:NEURON_NUM*NEURON_NUM-1];
    wire [NEURON_OUTPUT_WIDTH-1:0] z_mem [0:NEURON_NUM-1];
    wire [DELTA_CELL_WIDTH-1:0] delta_mem [0:NEURON_NUM-1];

    genvar i;
    generate 
    for (i=0; i<NEURON_NUM*NEURON_NUM; i=i+1) begin: MEM
        assign weights_mem[i] = w[i*WEIGHT_CELL_WIDTH+:WEIGHT_CELL_WIDTH];
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
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )
    ) uut (
        .clk        (clk        ),
        .rst        (rst        ),
        .layer      (layer      ),
        .z          (z          ),
        .z_valid    (z_valid    ),
        .z_ready    (z_ready    ),
        .delta      (delta      ),
        .delta_valid(delta_valid),
        .delta_ready(delta_ready),
        .w          (w          ),
        .w_valid    (w_valid    ),
        .w_ready    (w_ready    ),
        .error      (error      )
	);

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk             <= 0;
		rst             <= 1;
		layer           <= 0;

		z               <= {10'd800, 10'd700, 10'd600, 10'd500}; // 10, 20, 30, 40, 50
        z_valid         <= 0;
		delta           <= {10'd4,   10'd3,   10'd2,   10'd1};  // 5,  4,  3,  2,  1
        delta_valid     <= 0;

        w_ready         <= 0;

        #20 rst         <= 0;

        #20 z_valid     <= 1;
        #20 delta_valid <= 1;
        #20 w_ready     <= 1;

        #40 w_ready     <= 0;
        #20 z_valid     <= 0;

	end
      
endmodule

