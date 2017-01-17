`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   16:01:37 01/16/2017
// Design Name:   tensor_product
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_tensor_product.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: tensor_product
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_tensor_product;

    parameter VECTOR_SIZE    = 5,
              CELL_WIDTH     = 8,
              TILING_H       = 1, // the number of cells from vector b processed each turn
              TILING_V       = 2;  // the number of rows being processed each turn. 
	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [VECTOR_SIZE*CELL_WIDTH-1:0] a;
	reg [VECTOR_SIZE*CELL_WIDTH-1:0] b;

    // wires to memory
    wire [2*CELL_WIDTH-1:0] result_mem [VECTOR_SIZE-1:0][VECTOR_SIZE-1:0];
    wire [2*CELL_WIDTH-1:0] result_vec [VECTOR_SIZE*VECTOR_SIZE-1:0];
    genvar i, j;
    generate
    for (i=0; i<VECTOR_SIZE; i=i+1) begin
        for (j=0; j<VECTOR_SIZE; j=j+1) begin
            assign result_mem[i][j] = result[i*VECTOR_SIZE*2*CELL_WIDTH+j*2*CELL_WIDTH+:2*CELL_WIDTH];
            assign result_vec[i*VECTOR_SIZE+j] = result[i*VECTOR_SIZE*2*CELL_WIDTH+j*2*CELL_WIDTH+:2*CELL_WIDTH];
        end
    end
    endgenerate

	// Outputs
	wire [VECTOR_SIZE*VECTOR_SIZE*2*CELL_WIDTH-1:0] result;
	wire finish;

	// Instantiate the Unit Under Test (UUT)
	tensor_product 
    #(.VECTOR_SIZE(VECTOR_SIZE), .CELL_WIDTH(CELL_WIDTH), .TILING_H(TILING_H), .TILING_V(TILING_V))
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

        #20  rst = 1;
        #20  rst = 0;

        #20 start = 1;
        #2  start = 0;



	end
      
endmodule

