`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   07:27:44 12/29/2016
// Design Name:   activation
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/layer_multiplex_nn/t_activations.v
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

module t_activations;

    `include "params.vh"
    defparam max_neurons = 5;
    defparam uut.max_neurons = 5;

	// Inputs
	reg clk;
	reg rst;
	reg [lut_addr_size*max_neurons-1:0] addr;
	reg [9:0] valid_addr;
	reg [$clog2(max_neurons):0] neuron_count;

	// Outputs
	wire [lut_width*max_neurons-1:0] activations;
	wire [max_neurons-1:0] activations_valid;

	// Instantiate the Unit Under Test (UUT)
	activation uut (
		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.valid_addr(valid_addr), 
		.neuron_count(neuron_count), 
		.activations(activations), 
		.activations_valid(activations_valid)
	);

    always 
        #1 clk = ~clk;


	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		addr = 0;
		valid_addr = 0;
		neuron_count = 4;

        #10 rst = 1;
        #10 rst = 0;

        addr[0*lut_addr_size+:lut_addr_size] = 100;
        valid_addr[0] = 1;

        addr[1*lut_addr_size+:lut_addr_size] = 200;
        valid_addr[1] = 1;

        addr[2*lut_addr_size+:lut_addr_size] = 300;
        valid_addr[2] = 1;

        addr[3*lut_addr_size+:lut_addr_size] = 400;
        valid_addr[3] = 1;

        addr[4*lut_addr_size+:lut_addr_size] = 800;
        valid_addr[4] = 1;
        

        

	end
      
endmodule

