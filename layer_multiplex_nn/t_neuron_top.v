`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:58:28 12/27/2016
// Design Name:   neuron_top
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/t_neuron_top.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: neuron_top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module t_neuron_top;

    `include "params.vh"

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [$clog2(max_neurons)-1:0] input_signals;
    wire [169:0] weights;
    wire [89:0] inputs;

    reg signed [weight_size-1:0] weights_mem [max_neurons-1:0];
    reg signed [input_size-1:0]  inputs_mem   [max_neurons-1:0];

    genvar i;
    generate
    for (i=0; i<max_neurons; i=i+1) begin
        assign weights[i*weight_size+:weight_size] = weights_mem[i];
        assign inputs[i*input_size+:input_size] = inputs_mem[i];
    end
    endgenerate

	// Outputs
	wire [8:0] activation;

	// Instantiate the Unit Under Test (UUT)
	neuron_top uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.input_signals(input_signals), 
		.weights(weights), 
		.inputs(inputs), 
		.activation(activation)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 1;

		input_signals = 4;
        weights_mem[0] = 512; // 512 >>> 8 = 2
        weights_mem[1] = 50;
        weights_mem[2] = -7;
        weights_mem[3] = -1024;

        inputs_mem[0] = 128; // 128 >>> 8 = 0.5
        inputs_mem[1] = -64; // -64 >>> 8 = -0.25
        inputs_mem[2] = -12; // -12 >>> 8 ~~ -0.05
        inputs_mem[3] = 144; 

        #10 rst = 1;
        #10 rst = 0;

		// Wait 100 ns for global reset to finish
		#100;

	end
      
endmodule

