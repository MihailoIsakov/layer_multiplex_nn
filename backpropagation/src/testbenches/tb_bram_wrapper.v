`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:03:20 03/27/2017
// Design Name:   bram_wrapper
// Module Name:   /home/mihailo/development/projects/layer_multiplex_nn/backpropagation/src/testbenches/tb_bram_wrapper.v
// Project Name:  backpropagation
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: bram_wrapper
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_bram_wrapper;

	// Inputs
	reg clk;
	reg rst;
	reg [7:0] read_addr;
	reg read_addr_valid;
	reg read_data_ready;
	reg [7:0] write_addr;
	reg write_addr_valid;
	reg [31:0] write_data;
	reg write_data_valid;

	// Outputs
	wire read_addr_ready;
	wire [31:0] read_data;
	wire read_data_valid;
	wire write_addr_ready;
	wire write_data_ready;

	// Instantiate the Unit Under Test (UUT)
	bram_wrapper #(
        .INIT_FILE("targets_zeros.list") 
    ) uut (
		.clk(clk), 
		.rst(rst), 
		.read_addr(read_addr), 
		.read_addr_valid(read_addr_valid), 
		.read_addr_ready(read_addr_ready), 
		.read_data(read_data), 
		.read_data_valid(read_data_valid), 
		.read_data_ready(read_data_ready), 
		.write_addr(write_addr), 
		.write_addr_valid(write_addr_valid), 
		.write_addr_ready(write_addr_ready), 
		.write_data(write_data), 
		.write_data_valid(write_data_valid), 
		.write_data_ready(write_data_ready)
	);

    always
        #1 clk = ~clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 1;

		read_addr = 0;
		read_addr_valid = 0;

		read_data_ready = 0;

		write_addr = 0;
		write_addr_valid = 0;

		write_data = 0;
		write_data_valid = 0;


        #20 rst = 0;

        #20 read_addr = 2;
            read_addr_valid = 1;
        #2  read_addr_valid = 0; 
        // should be 0

        #10 read_data_ready = 1;
        #2  read_data_ready = 0;
        

        // overwrite
        #10 write_addr = 2;
            write_addr_valid = 1;
        #2  write_addr_valid = 0;
            
        
        #10 write_data = 100;
            write_data_valid = 1;
        #2  write_data_valid = 0;

        #20 read_addr = 2;
            read_addr_valid = 1;
        #2  read_addr_valid = 0; 
        // should be 100

        #10 read_data_ready = 1;
        #2  read_data_ready = 0;

        #20 read_addr = 3;
            read_addr_valid = 1;


	end
      
endmodule

