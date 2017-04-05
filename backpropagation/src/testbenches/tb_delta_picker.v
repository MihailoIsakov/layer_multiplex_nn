`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:53:46 04/05/2017
// Design Name:   delta_picker
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/src/testbenches/tb_delta_picker.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: delta_picker
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_delta_picker;

	// Inputs
	reg clk;
	reg rst;
	reg [1:0] layer;
	reg layer_valid;
	reg [31:0] fetcher;
	reg fetcher_valid;
	reg [31:0] propagator;
	reg propagator_valid;
	reg result_ready;

	// Outputs
	wire layer_ready;
	wire fetcher_ready;
	wire propagator_ready;
	wire [31:0] result;
	wire result_valid;

	// Instantiate the Unit Under Test (UUT)
	delta_picker #(
        .LAYER_MAX(3)    
    )uut (
		.clk(clk), 
		.rst(rst), 
		.layer(layer), 
		.layer_valid(layer_valid), 
		.layer_ready(layer_ready), 
		.fetcher(fetcher), 
		.fetcher_valid(fetcher_valid), 
		.fetcher_ready(fetcher_ready), 
		.propagator(propagator), 
		.propagator_valid(propagator_valid), 
		.propagator_ready(propagator_ready), 
		.result(result), 
		.result_valid(result_valid), 
		.result_ready(result_ready)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;

		layer = 3;
		layer_valid = 0;

		fetcher = 100;
		fetcher_valid = 0;

		propagator = 200;
		propagator_valid = 0;

		result_ready = 0;

        #10 rst = 0;

        #10 fetcher_valid = 1;
        #2  fetcher_valid = 0;

        #10 propagator_valid = 1;
        #2  propagator_valid = 0;
    
        #10 layer_valid = 1;
        #2  layer_valid = 0;

        #10 result_ready = 1;
        #2  result_ready = 0;

        // layer goes to 2
        #30 layer_valid = 1;
            layer = 2;
        #2  layer_valid = 0;

        #10 result_ready = 1;
        #2  result_ready = 0;

	end
      
endmodule

