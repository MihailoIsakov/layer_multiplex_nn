`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:06:26 01/17/2017
// Design Name:   weight_updater
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_weight_updater.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: weight_updater
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_weight_updater_error;

    parameter NEURON_NUM        = 5,  // size of the vectors a and delta
              ACTIVATION_WIDTH  = 9,  // width of each signal from the neurons
              DELTA_CELL_WIDTH  = 12, // width of each delta cell
              WEIGHT_CELL_WIDTH = 16, // width of individual weights
              FRACTION_WIDTH    = 0;

	// Inputs
	reg clk;
	reg rst;
	reg start;
    reg [NEURON_NUM*ACTIVATION_WIDTH-1:0]             a;
    reg [NEURON_NUM*DELTA_CELL_WIDTH-1:0]             delta;
    reg [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] w;

	// Outputs
	wire [NEURON_NUM*NEURON_NUM*WEIGHT_CELL_WIDTH-1:0] result;
	wire valid, error;

	// Instantiate the Unit Under Test (UUT)
	weight_updater #(
        .NEURON_NUM       (NEURON_NUM       ),
        .ACTIVATION_WIDTH (ACTIVATION_WIDTH ),
        .DELTA_CELL_WIDTH (DELTA_CELL_WIDTH ),
        .WEIGHT_CELL_WIDTH(WEIGHT_CELL_WIDTH),
        .FRACTION_WIDTH   (FRACTION_WIDTH   )
    ) updater (
		.clk   (clk   ),
		.rst   (rst   ),
		.start (start ),
		.a     (a     ),
		.delta (delta ),
		.w     (w     ),
		.result(result),
		.valid (valid ),
        .error (error )
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk   = 0;
		rst   = 0;
		start = 0;
		a     = {9'd50, 9'd40, 9'd30, 9'd20, 9'd10}; // 10, 20, 30, 40, 50
		delta = {12'd1000,  12'd4,  12'd3,  12'd2,  12'd1};  // 5,  4,  3,  2,  1
		w     = {16'd0, 16'd1, 16'd2, 16'd3, 16'd4, 16'd5, 16'd6, 16'd7, 16'd8, 16'd9, 16'd10, 16'd11, 16'd12, 16'd13, 16'd14, 16'd15, 16'd16, 16'd17, 16'd18, 16'd19, 16'd20, 16'd21, 16'd22, 16'd23, 16'd24};

        #20 rst = 1;
        #2  rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

