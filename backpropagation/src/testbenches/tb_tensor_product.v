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
              RESULT_CELL_WIDTH = 12, // width of the integer part of the result vector values
              FRACTION_WIDTH    = 0, // width of the fraction of both a and b values
              TILING_H          = 2, // the number of cells from vector b processed each turn
              TILING_V          = 2; // the number of rows being processed each turn.

	// Inputs
	reg clk;
	reg rst;

    // a
	reg [A_VECTOR_LEN*A_CELL_WIDTH-1:0] a;
    reg                                 a_valid;
    wire                                a_ready;

    // b
	reg [B_VECTOR_LEN*B_CELL_WIDTH-1:0] b;
    reg                                 b_valid;
    wire                                b_ready;

    // result
	wire [A_VECTOR_LEN*B_VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result;
	wire result_valid;
    reg  result_ready;
    
    // overflow
    wire error;
    
    // memory 
    wire [RESULT_CELL_WIDTH-1:0] result_mem [0:B_VECTOR_LEN-1][0:A_VECTOR_LEN-1];
    genvar i, j;
    generate
    for (i=0; i<B_VECTOR_LEN; i=i+1) begin
        for (j=0; j<A_VECTOR_LEN; j=j+1) begin
            assign result_mem[i][j] = result[i*B_VECTOR_LEN*RESULT_CELL_WIDTH+j*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH];
        end
    end
    endgenerate

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
		.a(a), 
        .a_valid(a_valid),
        .a_ready(a_ready),
		.b(b), 
        .b_valid(b_valid),
        .b_ready(b_ready),
		.result(result), 
        .result_valid(result_valid),
        .result_ready(result_ready),
        .error(error)
	);

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk <= 0;
		rst <= 1;

		a <= {-8'd50 , 8'd40 , 8'd30 , 8'd20 , 8'd10}; // 10 , 20 , 30 , 40 , 50
        a_valid <= 0;
		b <= {8'd1   , 8'd2  , -8'd3 , 8'd4  , 8'd5};  // 5  , 4  , 3  , 2  , 1
        b_valid <= 0;
        result_ready <= 0;

        #20  rst <= 0;

        #20 a_valid <= 1;
        #20 b_valid <= 1;
        #24 result_ready <= 1;
        #50 result_ready <= 0;

	end
      
endmodule

