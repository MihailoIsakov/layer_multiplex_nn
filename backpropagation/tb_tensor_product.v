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

    parameter A_VECTOR_LEN      = 5, // length of vector a
              B_VECTOR_LEN      = 5, // length of vector b
              A_CELL_WIDTH      = 8, // width of the integer part of fixed point vector values of a
              B_CELL_WIDTH      = 8, // width of the integer part of fixed point vector values of b
              RESULT_CELL_WIDTH = 20, // width of the integer part of the result vector values
              FRACTION_WIDTH    = 1, // width of the fraction of both a and b values
              TILING_H          = 10, // the number of cells from vector b processed each turn
              TILING_V          = 7; // the number of rows being processed each turn.

	// Inputs
	reg clk;
	reg rst;
	reg start;
	reg [A_VECTOR_LEN*A_CELL_WIDTH-1:0] a;
	reg [B_VECTOR_LEN*B_CELL_WIDTH-1:0] b;

    // wires to memory
    wire [RESULT_CELL_WIDTH-1:0] result_mem [0:B_VECTOR_LEN-1][0:A_VECTOR_LEN-1];
    //wire [2*RESULT_CELL_WIDTH-1:0] result_vec [B_VECTOR_LEN*A_VECTOR_SIZE-1:0];
    genvar i, j;
    generate
    for (i=0; i<B_VECTOR_LEN; i=i+1) begin
        for (j=0; j<A_VECTOR_LEN; j=j+1) begin
            assign result_mem[i][j] = result[i*B_VECTOR_LEN*RESULT_CELL_WIDTH+j*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH];
            //assign result_vec[i*VECTOR_SIZE+j] = result[i*VECTOR_SIZE*2*CELL_WIDTH+j*2*CELL_WIDTH+:2*CELL_WIDTH];
        end
    end
    endgenerate

	// Outputs
	wire [A_VECTOR_LEN*B_VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result;
	wire valid;

	// Instantiate the Unit Under Test (UUT)
	tensor_product 
    #(
        .A_VECTOR_LEN     (A_VECTOR_LEN     ),
        .B_VECTOR_LEN     (B_VECTOR_LEN     ),
        .A_CELL_WIDTH     (A_CELL_WIDTH     ),
        .B_CELL_WIDTH     (B_CELL_WIDTH     ),
        .FRACTION_WIDTH   (FRACTION_WIDTH   ),
        .RESULT_CELL_WIDTH(RESULT_CELL_WIDTH),
        .TILING_H         (TILING_H         ),
        .TILING_V         (TILING_V         ))
    uut (
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
		a = {-8'd50 , 8'd40 , 8'd30 , 8'd20 , 8'd10}; // 10 , 20 , 30 , 40 , 50
		b = {8'd1   , 8'd2  , -8'd3 , 8'd4  , 8'd5};  // 5  , 4  , 3  , 2  , 1

        #20  rst = 1;
        #20  rst = 0;

        #20 start = 1;
        #2  start = 0;

	end
      
endmodule

