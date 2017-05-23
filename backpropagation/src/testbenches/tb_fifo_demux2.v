`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:15:40 05/22/2017
// Design Name:   fifo_demux2
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/src/testbenches/tb_fifo_demux2.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo_demux2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_fifo_demux2;

	// Inputs
	reg clk;
	reg rst;
	reg [31:0] in;
	reg in_valid;
	reg select;
	reg select_valid;
	reg out0_ready;
	reg out1_ready;

	// Outputs
	wire in_ready;
	wire select_ready;
	wire [31:0] out0;
	wire out0_valid;
	wire [31:0] out1;
	wire out1_valid;

	// Instantiate the Unit Under Test (UUT)
	fifo_demux2 uut (
		.clk(clk), 
		.rst(rst), 
		.in(in), 
		.in_valid(in_valid), 
		.in_ready(in_ready), 
		.select(select), 
		.select_valid(select_valid), 
		.select_ready(select_ready), 
		.out0(out0), 
		.out0_valid(out0_valid), 
		.out0_ready(out0_ready), 
		.out1(out1), 
		.out1_valid(out1_valid), 
		.out1_ready(out1_ready)
	);

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk <= 0;
		rst <= 1;

		in <= 0;
		in_valid <= 0;

		select <= 0;
		select_valid <= 0;

		out0_ready <= 0;
		out1_ready <= 0;

        // start 
        
        #10 rst <= 0;

        #10 select <= 1;
            select_valid <= 1;
        #2  select_valid <= 0;

        #10 in <= 66;
            in_valid <= 1;
        #2  in_valid <= 0;

        #10 out0_ready <= 1; 
        #10 out1_ready <= 1; 

	end
      
endmodule

