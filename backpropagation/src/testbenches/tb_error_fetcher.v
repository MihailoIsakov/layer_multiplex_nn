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

    parameter NEURON_NUM          = 4,  // number of cells in the vectors a and delta
              NEURON_OUTPUT_WIDTH = 10, // size of the output of the neuron (z signal)
              DELTA_CELL_WIDTH    = 18, // width of each delta cell
              ACTIVATION_WIDTH    = 9,  // size of the neurons activation
              FRACTION_WIDTH      = 0,
              LAYER_ADDR_WIDTH    = 2,  // size of the layer number 
              LAYER_MAX           = 3,  // number of layers in the network
              SAMPLE_ADDR_SIZE    = 10, // size of the sample addresses
              TARGET_FILE         = "targets4.list";

	// Inputs
	reg clk;
	reg rst;
	reg [LAYER_ADDR_WIDTH-1:0] layer;
	reg [SAMPLE_ADDR_SIZE-1:0] sample_index;

	reg [NEURON_NUM*NEURON_OUTPUT_WIDTH-1:0] z;
    reg                                      z_valid;
    wire                                     z_ready;

	reg [NEURON_NUM*DELTA_CELL_WIDTH-1:0] delta_input;
    reg                                   delta_input_valid;
    wire                                  delta_input_ready;

	wire [NEURON_NUM*DELTA_CELL_WIDTH-1:0] delta_output;
	wire                                   delta_output_valid;
    reg                                    delta_output_ready;

    wire error;

	// Instantiate the Unit Under Test (UUT)
    error_fetcher #(
        .NEURON_NUM         (NEURON_NUM         ),
        .NEURON_OUTPUT_WIDTH(NEURON_OUTPUT_WIDTH),
        .DELTA_CELL_WIDTH   (DELTA_CELL_WIDTH   ),
        .ACTIVATION_WIDTH   (ACTIVATION_WIDTH   ),
        .FRACTION_WIDTH     (FRACTION_WIDTH     ),
        .LAYER_ADDR_WIDTH   (LAYER_ADDR_WIDTH   ),
        .LAYER_MAX          (LAYER_MAX          ),
        .SAMPLE_ADDR_SIZE   (SAMPLE_ADDR_SIZE   ),
        .TARGET_FILE        (TARGET_FILE        )
    ) uut (
    .clk               (clk               ), 
    .rst               (rst               ),
    .layer             (layer             ),
    .sample_index      (sample_index      ),
    .z                 (z                 ),
    .z_valid           (z_valid           ),
    .z_ready           (z_ready           ),
    .delta_input       (delta_input       ),
    .delta_input_valid (delta_input_valid ),
    .delta_input_ready (delta_input_ready ),
    .delta_output      (delta_output      ),
    .delta_output_valid(delta_output_valid),
    .delta_output_ready(delta_output_ready),
    .error             (error             )
	);

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk <= 0;
		rst <= 1;
		sample_index <= 0;
		layer <= LAYER_MAX;

		z <= 0;
        z_valid <= 0;

		delta_input <= 0;
		delta_input_valid <= 0;

        delta_output_ready <= 0;

        #10 rst <= 0;

        #20 
            z           <= {10'd1000, 10'd800, 10'd600, 10'd400, 10'd200}; // 10, 20, 30, 40, 50
            delta_input <= {8'd1    , 8'd2   , 8'd3   , 8'd4   , 8'd5};  // 5   , 4 , 3 , 2 , 1

        #10 
            z_valid <= 1;
            delta_input <= 1;
            delta_output_ready <= 1;


        #10 
            delta_input <= {11'd0, 11'b11111111111, 11'd0, 11'b11111111111};
            delta_input_valid <= 0;

        #20 delta_input_valid <= 1;
            
        //#100 layer <= 2;
	end
      
endmodule

