`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:51:19 12/30/2016
// Design Name:   neuron
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_neuron.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: neuron
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_neuron;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [44:0] inputs;
	reg [84:0] weights;

	// Outputs
	wire [9:0] out_value;
	wire out_valid;

	// Instantiate the Unit Under Test (UUT)
	neuron uut (
		.clk(clk),
		.rst(rst),
		.start(start),
		.inputs(inputs),
		.weights(weights),
		.out_value(out_value),
		.out_valid(out_valid)
	);

    always  
        #1 clk = ~clk;

	initial begin
        // sanity checks
        $display("FUNCTION_RANGE_HIGH <<< SIGNIFICANT = %d", 8 <<< (8 + 8));
        $display("FUNCTION_RANGE_LOW  <<< SIGNIFICANT = %d", -8 <<< (8 + 8));

		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		inputs = 0;
		weights = 0;

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
            inputs[8 :0]  = -40 ;
            inputs[17:9]  = 43  ;
            inputs[26:18] = 103 ;
            inputs[35:27] = 7   ;
            inputs[44:36] = -150;

            weights[16:0]  = 70  << 3;
            weights[33:17] = -5  << 3;
            weights[50:34] = -1  << 3;
            weights[67:51] = 10  << 3;
            weights[84:68] = -20 << 3;
        #2  start = 0;

        #20 start = 1;
            inputs[8 :0]  = 5  ;
            inputs[17:9]  = 20 ;
            inputs[26:18] = -50;
            inputs[35:27] = 1  ;
            inputs[44:36] = 200;

            weights[16:0]  = 150 << 3;
            weights[33:17] = 40  << 3;
            weights[50:34] = 20  << 3;
            weights[67:51] = 300 << 3;
            weights[84:68] = -3  << 3;
        #2  start = 0;

        // Saturate the neuron positively
        #20 start = 1;
            inputs[8 :0]  = 200;
            weights[16:0] = 50000;

        #2  start = 0;
        
        // Saturate the neuron positively
        #20 start = 1;
            inputs[8 :0]  = 200;
            weights[16:0] = -5000;

        #2  start = 0;

	end

endmodule

