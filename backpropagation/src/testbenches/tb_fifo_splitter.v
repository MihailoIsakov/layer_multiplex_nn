`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:25:11 03/16/2017
// Design Name:   fifo_splitter
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/tb_fifo_splitter.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: fifo_splitter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_fifo_splitter;

	// Inputs
	reg clk;
	reg rst;
	reg [31:0] data_in;
	reg data_in_valid;
	reg data_out1_ready;
	reg data_out2_ready;

	// Outputs
	wire data_in_ready;
	wire [31:0] data_out1;
	wire data_out1_valid;
	wire [31:0] data_out2;
	wire data_out2_valid;

	// Instantiate the Unit Under Test (UUT)
	fifo_splitter2 #(
        .DATA_WIDTH(32)
    )
    uut (
		.clk(clk), 
		.rst(rst), 
		.data_in(data_in), 
		.data_in_valid(data_in_valid), 
		.data_in_ready(data_in_ready), 
		.data_out1(data_out1), 
		.data_out1_valid(data_out1_valid), 
		.data_out1_ready(data_out1_ready), 
		.data_out2(data_out2), 
		.data_out2_valid(data_out2_valid), 
		.data_out2_ready(data_out2_ready)
	);

    always 
        #1 clk <= ~clk;

	initial begin
		// Initialize Inputs
		clk <= 0;
		rst <= 1;
		data_in <= 32'd666;
		data_in_valid <= 0;
		data_out1_ready <= 0;
		data_out2_ready <= 0;

            
        #10 rst <= 0;

        #10 data_in_valid <= 1;
        #2  data_in_valid <= 0;

        #10 data_out1_ready <= 1;
        #10 data_out2_ready <= 1;

        #10 data_in_valid <= 1;
	end
      
endmodule

