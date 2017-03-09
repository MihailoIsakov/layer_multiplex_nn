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

    parameter VECTOR_LEN        = 5,
              A_CELL_WIDTH      = 8,
              B_CELL_WIDTH      = 8,
              RESULT_CELL_WIDTH = 8,
              TILING            = 2;

	// Inputs
	reg clk;
	reg rst;
    reg [VECTOR_LEN*A_CELL_WIDTH-1:0] a;
    reg                               a_valid;
    reg [VECTOR_LEN*B_CELL_WIDTH-1:0] b;
    reg                               b_valid;
    reg                               result_ready;

	// Outputs
	wire [VECTOR_LEN*RESULT_CELL_WIDTH-1:0] result;
    wire                                    result_valid;
    wire                                    a_ready;
    wire                                    b_ready;
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
	vector_add 
    #(
        .VECTOR_LEN       (VECTOR_LEN       ),
        .A_CELL_WIDTH     (A_CELL_WIDTH     ),
        .B_CELL_WIDTH     (B_CELL_WIDTH     ),
        .RESULT_CELL_WIDTH(RESULT_CELL_WIDTH),
        .TILING           (TILING           ))
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

		a <= {-8'd50, 8'd40, 8'd30, 8'd20, -8'd10}; // 10, 20, 30, 40, 50
        a_valid <= 0;
		b <= {8'd1  , 8'd2 , -8'd3, 8'd4 , 8'd5};  // 5  , 4 , 3 , 2 , 1
        b_valid <= 0;
        result_ready <= 0;

        #10 rst <= 0;
    
        #20 a_valid <= 1;
        #10 b_valid <= 1;
        #5  a_valid <= 0;
        #5  b_valid <= 0;

        #20 result_ready <= 1;

        #20
            a = {8'd127, -8'd128, 8'd30, 8'd20, -8'd10}; // 10, 20, 30, 40, 50
            b = {8'd127, -8'd128, -8'd3, 8'd4 , 8'd5};  // 5  , 4 , 3 , 2 , 1
        #9  a_valid <= 1;
            b_valid <= 1;
            result_ready <= 1;



	end
      
endmodule

