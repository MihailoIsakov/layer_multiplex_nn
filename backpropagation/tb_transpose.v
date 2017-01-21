`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:08:07 01/21/2017
// Design Name:   transpose
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_transpose.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: transpose
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_transpose;

	// Inputs
	reg [95:0] input_matrix;

	// Outputs
	wire [95:0] output_matrix;

    // Memory
    wire [7:0] output_matrix_mem [0:11];
    genvar i;
    generate
    for (i=0; i<12; i=i+1) begin: MEM
        assign output_matrix_mem[i] = output_matrix[i*8+:8];
    end
    endgenerate

	// Instantiate the Unit Under Test (UUT)
	transpose uut (
		.input_matrix(input_matrix), 
		.output_matrix(output_matrix)
	);

	initial begin
		// Initialize Inputs
		input_matrix = {8'd11, 8'd10, 8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1, 8'd0};

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

