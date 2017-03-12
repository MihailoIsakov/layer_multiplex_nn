`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   02:46:16 01/22/2017
// Design Name:   vector_mac
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_vector_mac.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: vector_mac
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_vector_mac;

    parameter VECTOR_LEN        = 5,  // number of elements in the vectors
              A_CELL_WIDTH      = 8,  // width of elements in the vector a
              B_CELL_WIDTH      = 8,  // width of elements in the vector b
              RESULT_CELL_WIDTH = 10, // width of elements in the output vector
              TILING            = 5;  // number of mults generated for dot product

	// Inputs
	reg clk;
	reg rst;
	reg [VECTOR_LEN*A_CELL_WIDTH-1:0] a;
    reg                               a_valid;
    wire                              a_ready;
	reg [VECTOR_LEN*B_CELL_WIDTH-1:0] b;
    reg                               b_valid;
    wire                              b_ready;

	// Outputs
	wire [RESULT_CELL_WIDTH-1:0] result;
    wire                         result_valid;
    reg                          result_ready;
    wire error;

	// Instantiate the Unit Under Test (UUT)
    vector_mac #(
       .VECTOR_LEN       (VECTOR_LEN       ), 
       .A_CELL_WIDTH     (A_CELL_WIDTH     ), 
       .B_CELL_WIDTH     (B_CELL_WIDTH     ), 
       .RESULT_CELL_WIDTH(RESULT_CELL_WIDTH), 
       .TILING           (TILING           )
    ) uut (
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
		clk   <= 0;
		rst   <= 1;

		a     <= 0;
        a_valid <= 0;
		b     <= 0;
        b_valid <= 0;

        result_ready <= 0;

        #10 rst <= 0;

        #20 
            a     <= {8'd10, -8'd20, 8'd1, 8'd100, 8'd0};
            a_valid <= 1;
        #10 
            b     <= {8'd5,   8'd4,  8'd3, 8'd2,   8'd1};
            b_valid <= 1;

        #20 result_ready <= 1;

        #10 
            a_valid <= 0;
            b_valid <= 0;
            a     <= {8'd10, -8'd200, 8'd100, 8'd100, 8'd0};
            b     <= {8'd50,   8'd4,  8'd30, 8'd2,   8'd1};

        #20 a_valid <= 1;
            b_valid <= 1;

        #20 $stop;

	end
      
endmodule

