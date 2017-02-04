`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:28:17 01/19/2017
// Design Name:   lut
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_lut.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: lut
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_lut;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [59:0] inputs;

	// Outputs
	wire [53:0] outputs;
	wire valid;

    // Memory
    wire [8:0] outputs_mem [0:5];
    genvar i;
    generate
    for (i=0; i<6; i=i+1) begin: MEM
        assign outputs_mem[i] = outputs[i*9+:9];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	lut uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.inputs(inputs), 
		.outputs(outputs), 
		.valid(valid)
	);

    always 
        #1 clk = ~clk;
    
    initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		inputs = {10'd0, 10'd200, 10'd400, 10'd600, 10'd800, 10'd1000};

        #20 rst = 1;
        #2  rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

