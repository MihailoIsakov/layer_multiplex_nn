`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:30:42 01/01/2017
// Design Name:   layer
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_layer.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: layer
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_layer;

    parameter NUM_NEURON = 6;
    parameter NUM_INPUTS = 5;      // number of neurons from the previous layer connected to this neuron
    parameter INPUT_SIZE = 9;      // width of the input signals
    parameter WEIGHT_SIZE = 17;    // width of the weight signals
    parameter OUTPUT_SIZE = 10;    // width of the output signal 
    parameter INPUT_FRACTION = 8;  // number of bits below the radix point in the input
    parameter WEIGHT_FRACTION = 8; // number of bits below the radix point in the weight
    // for the output of OUTPUT_SIZE; FRACTION_BITS is the number of bits below the radix point that are taken into account
    parameter FRACTION_BITS = 7;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [5:0] active;
	wire [44:0] inputs;
	wire [509:0] weights;

	// Outputs
	wire [59:0] out_values;
	wire [5:0] out_valid;

    // memories
    reg [INPUT_SIZE-1:0] inputs_mem [0:NUM_INPUTS-1];
    reg [WEIGHT_SIZE-1:0] weights_mem [0:NUM_INPUTS*NUM_NEURON-1];
    wire [OUTPUT_SIZE-1:0] outputs_mem [0:NUM_NEURON-1];
    genvar x;
    generate
    for (x=0; x<NUM_INPUTS; x=x+1) begin: MEM_INPUT
         assign inputs[x*INPUT_SIZE+:INPUT_SIZE] = inputs_mem[x];
    end
    for (x=0; x<NUM_NEURON; x=x+1) begin: MEM_OUTPUT
        assign outputs_mem[x] = out_values[x*OUTPUT_SIZE+:OUTPUT_SIZE];
    end
    for (x=0; x<NUM_INPUTS*NUM_NEURON; x=x+1) begin: MEM_WEIGHT
        assign weights[x*WEIGHT_SIZE+:WEIGHT_SIZE] = weights_mem[x];
    end
    endgenerate


	// Instantiate the Unit Under Test (UUT)
	layer uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.active(active), 
		.inputs(inputs), 
		.weights(weights), 
		.out_values(out_values), 
		.out_valid(out_valid)
	);

    always
        #1 clk = ~clk;
        

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		active = 0;
		//inputs_mem = 0;
		//weights_mem = 0;

        #10 rst = 1;
        #10 rst = 0;

        #10 active = 1;
            inputs_mem[0]  = -40 ;
            inputs_mem[1]  = 43  ;
            inputs_mem[2] = 103 ;
            inputs_mem[3] = 7   ;
            inputs_mem[4] = -150;

            weights_mem[0]  = 70  << 3;
            weights_mem[1]  = -5  << 3;
            weights_mem[2]  = -1  << 3;
            weights_mem[3]  = 10  << 3;
            weights_mem[4]  = -20 << 3;
            weights_mem[5]  = 100;
            weights_mem[6]  = 200;
            weights_mem[7]  = 300;
            weights_mem[8]  = 400;
            weights_mem[9]  = 500;
            weights_mem[10] = 1000;
            weights_mem[11] = 2000;
            weights_mem[12] = 3000;
            weights_mem[13] = 4000;
            weights_mem[14] = 5000;
            weights_mem[15] = 10000;
            weights_mem[16] = 20000;
            weights_mem[17] = 30000;
            weights_mem[18] = 40000;
            weights_mem[19] = 50000;
            weights_mem[20] = 10000;
            weights_mem[21] = 20000;
            weights_mem[22] = 30000;
            weights_mem[23] = 40000;
            weights_mem[24] = 50000;
            weights_mem[25] = 50000;
            weights_mem[26] = 10000;
            weights_mem[27] = 20000;
            weights_mem[28] = 30000;
            weights_mem[29] = 40000;


        #10 start = 1;
        #2 start = 0;

        #50 active = 5'b00011;
        #10 start = 1;
        #2 start = 0;

        #50 active = 5'b11111;
        #10 start = 1;
        #2 start = 0;

	end
      
endmodule

