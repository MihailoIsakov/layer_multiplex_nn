`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:55:40 01/23/2017
// Design Name:   vector_dot2
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_vector_dot2.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vector_dot2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_vector_dot2;

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [5*8-1:0] a;
	reg [5*10-1:0] b;

	// Outputs
	wire [5*(8+10)-1:0] result;
	wire valid;

    // Memories
    wire [15:0] result_mem [0:4];
    genvar i;
    generate
    for (i=0; i<5; i=i+1) begin: MEM
        assign result_mem[i] = result[i*18+:18];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	vector_dot2 #(.VECTOR_SIZE(5), .CELL_A_WIDTH(8), .CELL_B_WIDTH(10), .TILING(2))
	vector_dot2  (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.a(a), 
		.b(b), 
		.result(result), 
		.valid(valid)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;
		a = {8'd50,  8'd40,  8'd30,  8'd20,   8'd10}; // 10, 20, 30, 40, 50
		b = {10'd1, -10'd2,  10'd4, -10'd10,  10'd16};  // 5,  4,  3,  2,  1

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
        #2  start = 0;

        #40 start = 1;
        #2  start = 0;

	end
      
endmodule

