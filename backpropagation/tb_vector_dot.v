`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   10:33:14 01/17/2017
// Design Name:   vector_dot
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

module tb_vector_dot;
    parameter VECTOR_LEN        = 5,
              A_CELL_WIDTH      = 8,
              B_CELL_WIDTH      = 8,
              RESULT_CELL_WIDTH = 10,
              FRACTION          = 2,
              TILING            = 1;

	// Inputs
	reg clk;
	reg rst;
	reg start;
    reg [VECTOR_LEN*A_CELL_WIDTH-1:0] a;
    reg [VECTOR_LEN*B_CELL_WIDTH-1:0] b;

	// Outputs
	wire [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result;
	wire valid;
    wire error;

    // memory
    wire [RESULT_CELL_WIDTH-1:0] result_mem [0:VECTOR_LEN-1];
    genvar i;
    generate
    for (i=0; i<VECTOR_LEN; i=i+1) begin: MEM
        assign result_mem[i] = result[i*RESULT_CELL_WIDTH+:RESULT_CELL_WIDTH];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	vector_dot 
    #(
        .VECTOR_LEN       (VECTOR_LEN       ),
        .A_CELL_WIDTH     (A_CELL_WIDTH     ),
        .B_CELL_WIDTH     (B_CELL_WIDTH     ),
        .RESULT_CELL_WIDTH(RESULT_CELL_WIDTH),
        .FRACTION         (FRACTION         ),
        .TILING           (TILING           ))
    uut (
		.clk(clk), 
		.rst(rst), 
		.start(start), 
		.a(a), 
		.b(b), 
		.result(result), 
		.valid(valid),
        .error(error)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		start = 0;

        #20 rst = 1;
        #20 rst = 0;

        #20 start = 1;
            a = {8'd50, 8'd31, 8'd30, 8'd20, -8'd10}; // 40, 80, 120, 160, 200
            b = {8'd4 , -8'd3, -8'd3, 8'd4 ,  8'd1 };   // 20, 16, 12,  8,   4
        #2  start = 0;

		
        #40 start = 1;
            a = {8'd50,  8'd120,  8'd127, 8'd20, -8'd10}; // 40  , 80, 120, 160, 200
            b = {8'd10, -8'd120, -8'd128, 8'd40,  8'd50};   // 20, 16, 12 , 8  , 4
        #2  start = 0;

	end
      
endmodule

