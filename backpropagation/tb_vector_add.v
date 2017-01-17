`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:33:14 01/17/2017
// Design Name:   vector_add
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_vector_add.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vector_add
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_vector_add;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [39:0] a;
	reg [39:0] b;

	// Outputs
	wire [44:0] result;
	wire finish;

    // memory
    wire [8:0] result_mem [0:4];
    genvar i;
    generate
    for (i=0; i<5; i=i+1) begin: MEM
        assign result_mem[i] = result[i*9+:9];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	vector_add 
    #(.TILING(2))
    uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.a(a), 
		.b(b), 
		.result(result), 
		.finish(finish)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		a = {8'd50, 8'd40, 8'd30, 8'd20, 8'd10}; // 10, 20, 30, 40, 50
		b = {8'd1,  8'd2,  8'd3,  8'd4,  8'd5};  // 5,  4,  3,  2,  1

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
        #2  start = 0;

        #40 start = 1;
        #2  start = 0;

	end
      
endmodule

