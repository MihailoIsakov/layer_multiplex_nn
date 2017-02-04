`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:54:53 01/15/2017
// Design Name:   activation_stack
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_stack.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: activation_stack
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_stack;
    parameter NEURON_NUM       = 6, 
              ACTIVATION_WIDTH = 8,
              STACK_ADDR_WIDTH = 10;
    localparam STACK_WIDTH = NEURON_NUM*ACTIVATION_WIDTH; 

	// Inputs
	reg clk;
	reg [STACK_WIDTH-1:0] input_data;
	reg [9:0] input_addr;
	reg input_wr_en;
	reg [9:0] output_addr;

	// Outputs
	wire [STACK_WIDTH-1:0] output_data0;
	wire [STACK_WIDTH-1:0] output_data1;

	// Instantiate the Unit Under Test (UUT)
	activation_stack uut (
		.clk(clk), 
		.input_data(input_data), 
		.input_addr(input_addr), 
		.input_wr_en(input_wr_en), 
		.output_addr(output_addr), 
		.output_data0(output_data0), 
		.output_data1(output_data1)
	);

    always 
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		input_data = 0;
		input_addr = 0;
		input_wr_en = 0;
		output_addr = 0;

        #20 input_data = 100;
            input_addr = 0;
            input_wr_en = 1;
        #2  input_data = 200;
            input_addr = 1;
            input_wr_en = 1;
        #2  input_data = 350;
            input_addr = 2;
            input_wr_en = 1;
        #2  input_data = 400;
            input_addr = 3;
            input_wr_en = 1;
        #2  input_data = 450;
            input_addr = 4;
            input_wr_en = 1;
        #2  input_wr_en = 0;

        #5 output_addr = 0;
        #5 output_addr = 1;
        #5 output_addr = 2;
        #5 output_addr = 3;
        #5 output_addr = 4;
        #5 output_addr = 5;
	end
      
endmodule

