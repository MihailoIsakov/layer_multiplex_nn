`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:44:20 03/26/2017
// Design Name:   fifo_mux2
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_fifo_mux2.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo_mux2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_fifo_mux2;

	// Inputs
	reg clk;
    // a
	reg [31:0] a;
	reg a_valid;
    wire a_ready;
    // b
	reg [31:0] b;
	reg b_valid;
    wire b_ready;
    // select
    reg select;
    reg select_valid;
    wire select_ready;
    // result
    wire [31:0] result;
    wire result_valid;
    reg result_ready;

	// Instantiate the Unit Under Test (UUT)
	fifo_mux2 uut (
		.clk(clk), 
		.a(a), 
		.a_valid(a_valid), 
		.a_ready(a_ready), 
		.b(b), 
		.b_valid(b_valid),
        .b_ready(b_ready),
        .select(select),
        .select_valid(select_valid),
        .select_ready(select_ready),
        .result(result),
        .result_valid(result_valid),
        .result_ready(result_ready)
	);

    always
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk <= 0;
		a <= 100;
		a_valid <= 0;
		b <= 256;
		b_valid <= 0;
        select <= 0;
        select_valid <= 0;
        result_ready <= 0;

        #20 a_valid      <= 1;
        #20 select       <= 0;
            select_valid <= 1;
        #20 result_ready <= 1;
        #20 select       <= 1; // select b
            select_valid <= 0;
        #20 select_valid <= 1;
        #20 b_valid      <= 1;
        #20 result_ready <= 0;

	end
      
endmodule

