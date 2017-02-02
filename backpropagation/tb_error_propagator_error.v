`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:01:04 01/23/2017
// Design Name:   error_propagator
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_error_propagator.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: error_propagator
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_error_propagator_error;

    parameter MATRIX_WIDTH       = 4,  // width of the weight matrix aka the number of columns
              MATRIX_HEIGHT      = 5,  // height of the weight matrix aka the number of rows and size of vector
              DELTA_CELL_WIDTH   = 8,  // width of each delta cell in bits
              WEIGHTS_CELL_WIDTH = 8,  // widht of each matrix cell in bits
              NEURON_ADDR_WIDTH  = 10, // width of activations from neurons before the sigmoid
              ACTIVATION_WIDTH   = 9,  // cell width after sigmoid
              FRACTION_WIDTH     = 0,
              TILING_ROW         = 3,  // number of vector_mac units to create
              TILING_COL         = 3;  // number of multipliers per vector_mac unit

    `include "log2.v"

    localparam DW = DELTA_CELL_WIDTH;

	// Inputs
	reg clk;
	reg rst;
	reg                                                     start;
	reg [MATRIX_HEIGHT*DELTA_CELL_WIDTH-1:0]                delta_input;
	reg [MATRIX_WIDTH *NEURON_ADDR_WIDTH-1:0]               z;
	reg [MATRIX_WIDTH*MATRIX_HEIGHT*WEIGHTS_CELL_WIDTH-1:0] w;

	// Outputs
	wire [MATRIX_WIDTH*DELTA_CELL_WIDTH-1:0] delta_output;
	wire valid, error;

    // Memory
    wire [DELTA_CELL_WIDTH-1:0] delta_output_mem [MATRIX_WIDTH-1:0];
    genvar i;
    for (i=0; i<MATRIX_WIDTH; i=i+1) begin: MEM
        assign delta_output_mem[i] = delta_output[i*DELTA_CELL_WIDTH+:DELTA_CELL_WIDTH];
    end


	// Instantiate the Unit Under Test (UUT)
    error_propagator #(
        .MATRIX_WIDTH      (MATRIX_WIDTH      ),
        .MATRIX_HEIGHT     (MATRIX_HEIGHT     ),
        .DELTA_CELL_WIDTH  (DELTA_CELL_WIDTH  ),
        .WEIGHTS_CELL_WIDTH(WEIGHTS_CELL_WIDTH),
        .NEURON_ADDR_WIDTH (NEURON_ADDR_WIDTH ),
        .ACTIVATION_WIDTH  (ACTIVATION_WIDTH  ),
        .FRACTION_WIDTH    (FRACTION_WIDTH    ),
        .TILING_ROW        (TILING_ROW        ),
        .TILING_COL        (TILING_COL        )
    ) uut (
		.clk         (clk         ),
		.rst         (rst         ),
		.start       (start       ),
		.delta_input (delta_input ),
		.z           (z           ),
		.w           (w           ),
		.delta_output(delta_output),
		.valid       (valid       ),
        .error       (error       )
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		delta_input = {12'd1, 12'd1, 12'd1, 12'd1, 12'd1}; // 10, 20, 30, 40, 50
		z = {10'd250, 10'd220, 10'd190, 10'd120};  // 4,  3,  2,  1
        w = {8'd20, 8'd19, 8'd18, 8'd17, 8'd16, 8'd15, 8'd14, 8'd13, 8'd12, 8'd11, 8'd10, 8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};
        // [  45.,  100.,  165.,  240.]
        
        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

