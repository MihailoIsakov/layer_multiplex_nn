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
	wire [6*9-1:0] outputs;
    wire [8:0]  outputs_mem [5:0];
	wire stable;

    genvar i;
    generate
        for (i=0; i<6; i=i+1) begin: MEM
            assign inputs_mem[i] = inputs[i*10+:10];
            assign outputs_mem[i] = outputs[i*9+:9];
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

        #100 inputs[ 9: 0] = 10'd100;
             inputs[19:10] = 10'd300;
             inputs[29:20] = 10'd500;
             inputs[39:30] = 10'd700;

        #100 inputs[49:40] = 10'd900;
             inputs[59:50] = 10'd1000;

        #100 // manual
		     inputs = 0;
             // 0.887123654 with 16 bits below radix. Shift so that 7 bits remain
             // sig(0.887123654) = 0.7082962393502449 * 255 = 180
             inputs[ 9: 0] = (58138 >>> 10) + 512; 
             // sig(-265853.4540949338) = 0.01701327359900143 * 255 =  4.338384767745365
             inputs[19:10] = (-265853 >>> 10) + 512;

	end
      
endmodule

