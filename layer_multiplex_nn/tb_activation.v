`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   03:22:54 01/03/2017
// Design Name:   activation
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/tb_activation.v
// Project Name:  layer_multiplex_nn
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: activation
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_activation;

	// Inputs
	reg clk;
	reg rst;
	reg [59:0] inputs;
    wire [9:0] inputs_mem [5:0];

	// Outputs
	wire [47:0] outputs;
    wire [7:0]  outputs_mem [0:5];
	wire stable;

    genvar i;
    generate
        for (i=0; i<6; i=i+1) begin: MEM
            assign outputs_mem[i] = outputs[i*8+:8];
            assign inputs_mem[i] = inputs[i*10+:10];
        end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	activation uut (
		.clk(clk), 
		.rst(rst), 
		.inputs(inputs), 
		.outputs(outputs), 
		.stable(stable)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		inputs = {10'd0, 10'd200, 10'd400, 10'd600, 10'd800, 10'd1023};

        #20 rst = 1;
        #20 rst = 0;

        #40 inputs[ 9: 0] = 10'd100;
        #2  inputs[19:10] = 10'd300;
        #4  inputs[29:20] = 10'd500;
        #8  inputs[39:30] = 10'd700;

        #31 inputs[49:40] = 10'd900;
        #31 inputs[59:50] = 10'd1000;

	end
      
endmodule

