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

module tb_backprop_single_layer;

    parameter NEURON_NUM          = 4,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              DELTA_CELL_WIDTH    = 10, // width of each delta cell
              WEIGHT_CELL_WIDTH   = 16, // width of individual weights
              FRACTION_WIDTH      = 8,
              LAYER_ADDR_WIDTH    = 2,
              LAYER_MAX           = 2,  // number of layers in the network
              LEARNING_RATE_SHIFT = 0,
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets4.list",
              WEIGHT_INIT_FILE    = "weights4x4.list";

	// Inputs
	reg clk;
	reg rst;

    // layer
    reg [LAYER_ADDR_WIDTH-1:0]                         layer;
    reg                                                layer_valid;
    wire                                               layer_ready;

    // sample
    reg [SAMPLE_ADDR_SIZE-1:0]                         sample;
    reg                                                sample_valid;
    wire                                               sample_ready;

    // z 
    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z;
    reg                                                z_valid;
    wire                                               z_ready;

    // z_prev
    reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0]           z_prev;
    reg                                                z_prev_valid;
    wire                                               z_prev_ready;
    
	// Outputs
    wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] weights;
    wire                                               weights_valid;
    reg                                                weights_ready;

    // overflow
    wire                                               error;

    integer i;
	// Instantiate the Unit Under Test (UUT)
    backpropagator #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .WEIGHT_CELL_WIDTH  (WEIGHT_CELL_WIDTH  ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LEARNING_RATE_SHIFT(LEARNING_RATE_SHIFT),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          ),
        .SAMPLE_ADDR_SIZE   (SAMPLE_ADDR_SIZE   ),
        .TARGET_FILE        (TARGET_FILE        ),
        .WEIGHT_INIT_FILE   (WEIGHT_INIT_FILE   )) 
    bp (
        .clk          (clk          ),
        .rst          (rst          ),
        .layer        (layer        ),
        .layer_valid  (layer_valid  ),
        .layer_ready  (layer_ready  ),
        .sample       (sample       ),
        .sample_valid (sample_valid ),
        .sample_ready (sample_ready ),
        .z            (z            ),
        .z_valid      (z_valid      ),
        .z_ready      (z_ready      ),
        .z_prev       (z_prev       ),
        .z_prev_valid (z_prev_valid ),
        .z_prev_ready (z_prev_ready ),
        .weights      (weights      ),
        .weights_valid(weights_valid),
        .weights_ready(weights_ready),
        .error        (error        )
    );

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk           <= 0;
		rst           <= 1;

		layer         <= LAYER_MAX;
        layer_valid   <= 0;

		sample        <= 0;
        sample_valid  <= 0;

		z             <= {10'd300, 10'd400, 10'd600, 10'd700};
        z_valid       <= 1'b0;

		z_prev        <= {10'd300, 10'd400, 10'd600, 10'd700};
        z_prev_valid  <= 1'b0;

        weights_ready <= 1'b0;

        for (i=0; i<10; i=i+1) begin
            #10 rst       <= 0;

            #10 layer_valid <= 1;
            #2  layer_valid <= 0;

            #10 sample_valid <= 1;
            #2  sample_valid <= 0;

            #20 z_valid       <= 1;
            #2  z_valid       <= 0;

            #20 z_prev_valid  <= 1;
            #2  z_prev_valid  <= 0;

            #20 weights_ready <= 1'b1;
            #2  weights_ready <= 1'b0;
            
        end
	end
endmodule

